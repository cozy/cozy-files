
jade = require 'jade'
async = require 'async'
archiver = require 'archiver'
moment = require 'moment'
log = require('printit')
    prefix: 'folders'

sharing = require '../helpers/sharing'
pathHelpers = require '../helpers/path'
Folder = require '../models/folder'
File = require '../models/file'
CozyInstance = require '../models/cozy_instance'

publicfoldertemplate = require('path').join __dirname, '../views/publicfolder.jade'
template = require('path').join __dirname, '../views/index.jade'

KB = 1024
MB = KB * KB


## Helpers ##


module.exports.fetch = (req, res, next, id) ->
    Folder.request 'all', key: id, (err, folder) ->
        if err or not folder or folder.length is 0
            unless err?
                err = new Error 'File not found'
                err.status = 404
                err.template =
                    name: '404'
                    params:
                        localization: require '../lib/localization_manager'
                        isPublic: req.url.indexOf('public') isnt -1
            next err
        else
            req.folder = folder[0]
            next()


findFolder = (id, callback) ->
    Folder.find id, (err, folder) =>
        if err or not folder
            callback "Folder not found"
        else
            callback null, folder


getFolderPath = (id, cb) ->
    if id is 'root'
        cb null, ""
    else
        findFolder id, (err, folder) ->
            if err
                cb err
            else
                cb null, folder.path + '/' + folder.name, folder


normalizePath = (path) ->
    path = "/#{path}" if path[0] isnt '/'
    path = "" if path is "/"
    path

## Actions ##

# New folder creation operations:
# * Check if given name is valid
# * Check if folder already exists
# * Tag folder with parent folder tags
# * Create Folder and index its name
# * Send notification if required
module.exports.create = (req, res, next) ->
    folder = req.body
    folder.path = normalizePath folder.path

    if (not folder.name) or (folder.name is "")
        next new Error "Invalid arguments"
    else
        Folder.all (err, folders) =>
            available = pathHelpers.checkIfPathAvailable folder, folders
            if not available
                res.send error: true, msg: "This folder already exists", 400
            else
                fullPath = folder.path
                parents = folders.filter (tested) ->
                    fullPath is tested.getFullPath()

                now = moment().toISOString()
                createFolder = ->
                    folder.creationDate = now
                    folder.lastModification = now

                    Folder.createNewFolder folder, (err, newFolder) ->
                        return next err if err
                        who = req.guestEmail or 'owner'
                        sharing.notifyChanges who, newFolder, (err) ->
                            # ignore this error
                            console.log err if err
                            res.send newFolder, 200

                # inherit its tags
                if parents.length > 0
                    parent = parents[0]

                    folder.tags = parent.tags

                    parent.lastModification = now
                    parent.save (err) ->
                        if err then next err
                        else createFolder()
                else
                    folder.tags = []
                    createFolder()

module.exports.find = (req, res, next) ->
    res.send req.folder


module.exports.tree = (req, res, next) ->
    folderChild = req.folder
    folderChild.getParents (err, folders) =>
        if err then next err
        else
            res.send folders, 200

# Get path for all folders
module.exports.list = (req, res, next) ->
    Folder.allPath (err, paths) ->
        if err then next err
        else
            res.send paths

module.exports.modify = (req, res, next) ->
    body = req.body
    body.path = normalizePath body.path if body.path?
    folder = req.folder

    if (not req.body.name?) \
       and (not req.body.public?) \
       and (not req.body.tags?) \
       and (not req.body.path?)
        return res.send error: true, msg: "Data required", 400

    previousName = folder.name
    newName = if body.name? then body.name else previousName
    previousPath = folder.path
    newPath = if body.path? then body.path else previousPath

    oldRealPath = "#{previousPath}/#{previousName}"
    newRealPath = "#{newPath}/#{newName}"

    newTags = req.body.tags or []
    newTags = newTags.filter (tag) -> typeof tag is 'string'
    isPublic = req.body.public

    updateIfIsSubFolder = (file, cb) ->

        if file.path.indexOf(oldRealPath) is 0
            modifiedPath = file.path.replace oldRealPath, newRealPath

            # add new tags from parent, keeping the old ones
            oldTags = file.tags
            tags = [].concat oldTags
            for tag in newTags
                tags.push tag if tags.indexOf tag is -1

            data =
                path: modifiedPath
                tags: tags

            file.updateAttributes data, cb
        else
            cb null

    updateTheFolder = ->
        # update the folder itself
        data =
            name: newName
            path: newPath
            public: isPublic
            tags: newTags
            lastModification: moment().toISOString()

        data.clearance = req.body.clearance if req.body.clearance

        folder.updateParentModifDate (err) ->
            log.raw err if err

            folder.updateAttributes data, (err) =>
                return next err if err

                folder.updateParentModifDate (err) ->
                    log.raw err if err

                    folder.index ["name"], (err) ->
                        log.raw err if err
                        res.send success: 'File succesfuly modified', 200

    updateFoldersAndFiles = (folders)->
        # update all folders
        async.each folders, updateIfIsSubFolder, (err) ->
            if err then next err
            else
                # update all files
                File.all (err, files) =>
                    if err then next err
                    else
                        async.each files, updateIfIsSubFolder, (err) ->
                            if err then next err
                            else
                                updateTheFolder()

    Folder.byFullPath key: newRealPath, (err, sameFolders) ->
        return next err if err

        if sameFolders.length > 0 and \
           sameFolders[0].id isnt req.body.id
            res.send error: true, msg: "The name already in use", 400
        else
            Folder.all (err, folders) ->
                return next err if err
                updateFoldersAndFiles folders


# Prior to deleting target folder, it deletes its subfolders and the files
# listed in the folder.
module.exports.destroy = (req, res, next) ->
    currentFolder = req.folder
    directory = "#{currentFolder.path}/#{currentFolder.name}"

    destroyIfIsSubdirectory = (file, cb) ->
        pathToTest = "#{file.path}/"
        # the trailing slash ensures that folder with the same prefix
        # won't be deleted
        if pathToTest.indexOf("#{directory}/") is 0
            file.destroy cb
        else
            cb null

    destroySubFolders = (callback) ->
        Folder.all (err, folders) ->
            if err then next err
            else
                # Remove folders in the current folder
                async.each folders, destroyIfIsSubdirectory, (err) ->
                    if err then next err
                    else
                        callback()

    destroySubFiles = (callback) ->
        File.all (err, files) =>
            if err then next err
            else
                # Remove files in this directory
                async.each files, destroyIfIsSubdirectory, (err) ->
                    if err then next err
                    else
                        callback()

    destroySubFolders ->
        # Remove the current folder
        destroySubFiles ->
            currentFolder.destroy (err) ->
                if err then next err
                else
                    currentFolder.updateParentModifDate (err) ->
                        log.raw err if err
                        res.send
                            success: "Folder succesfuly deleted: #{directory}"


module.exports.findFiles = (req, res, next) ->
    getFolderPath req.body.id, (err, key) ->
        if err then next err
        else
            File.byFolder key: key ,(err, files) ->
                if err then next err
                else
                    res.send files, 200


module.exports.allFolders = (req, res, next) ->
    Folder.all (err, folders) ->
        if err then next err
        else res.send folders

module.exports.findContent = (req, res, next) ->
    getFolderPath req.body.id, (err, key, folder) ->
        if err? then next err
        else
            async.parallel [
                (cb) -> Folder.byFolder key: key, cb
                (cb) -> File.byFolder key: key, cb
                (cb) ->
                    if req.body.id is "root"
                        cb null, []
                    else
                        # if it's a request from a guest, we need to limit the result
                        if req.url.indexOf('/public/') isnt -1
                            sharing.limitedTree folder, req, (parents, authorized) -> cb null, parents
                        else
                            folder.getParents cb
            ], (err, results) ->

                if err? then next err
                else
                    [folders, files, parents] = results
                    content = folders.concat files
                    res.send 200, {content, parents}

module.exports.findFolders = (req, res, next) ->
    getFolderPath req.body.id, (err, key) ->
        if err then next err
        else
            Folder.byFolder key: key ,(err, files) ->
                if err then next err
                else
                    res.send files, 200


module.exports.search = (req, res, next) ->
    sendResults = (err, files) ->
        if err then next err
        else
            res.send files

    query = req.body.id
    query = query.trim()

    if query.indexOf('tag:') isnt -1
        parts = query.split()
        parts = parts.filter (part) -> part.indexOf 'tag:' isnt -1
        tag = parts[0].split('tag:')[1]
        Folder.request 'byTag', key: tag, sendResults
    else
        Folder.search "*#{query}*", sendResults

module.exports.searchContent = (req, res, next) ->

    query = req.body.id
    query = query.trim()

    isPublic = req.url.indexOf('/public/') is 0
    key = req.query.key
    # if the clearance is 'public', we don't allow the search (for privacy reasons)
    if isPublic and not key?.length > 0
        err = new Error 'You cannot access public search result'
        err.status = 401
        next err
    else
        if query.indexOf('tag:') isnt -1
            parts = query.split()
            parts = parts.filter (part) -> part.indexOf 'tag:' isnt -1
            tag = parts[0].split('tag:')[1]
            requests = [
                (cb) -> Folder.request 'byTag', key: tag, cb
                (cb) -> File.request 'byTag', key: tag, cb
            ]
        else
            requests = [
                (cb) -> Folder.search "*#{query}*", cb
                (cb) -> File.search "*#{query}*", cb
            ]

        async.parallel requests, (err, results) ->
            if err? then next err
            else
                [folders, files] = results
                content = folders.concat files

                sendResults = (results) -> res.send 200, results

                # if there is a key we must filter the results so it doesn't display unshared files and folders
                if key?
                    isAuthorized = (element, callback) ->
                        sharing.checkClearance element, req, (authorized) ->
                            callback authorized and element.clearance isnt 'public'

                    async.filter content, isAuthorized, (results) ->
                        sendResults results
                else
                    sendResults content

# List files contained in the folder and return them as a zip archive.
# TODO: add subfolders
module.exports.zip = (req, res, next) ->
    folder = req.folder
    archive = archiver('zip')

    addToArchive = (file, cb) ->
        stream = file.getBinary "file", (err, resp, body) =>
            if err then next err
        name = file.path.replace(key, "") + "/" + file.name
        archive.append stream, name: name, cb

    makeZip = (zipName, files) ->
        async.eachSeries files, addToArchive, (err) ->
            if err then next err
            else
                archive.pipe res

                disposition = "attachment; filename=\"#{zipName}.zip\""
                res.setHeader 'Content-Disposition', disposition
                res.setHeader 'Content-Type', 'application/zip'

        archive.finalize (err, bytes) ->
            if err
                res.send error: true, msg: "Server error occured: #{err}", 500
            else
                console.log "Zip created"

    key = "#{folder.path}/#{folder.name}"
    File.all (err, files) ->
        if err then next err
        else
            zipName = folder.name?.replace(/\W/g, '')

            # check that the name is not already taken
            selectedFiles = files.filter (file) ->
                "#{file.path}/".indexOf("#{key}/") is 0

            makeZip zipName, selectedFiles


module.exports.changeNotificationsState = (req, res, next) ->
    folder = req.folder
    sharing.limitedTree folder, req, (path, rule) ->
        if not req.body.notificationsState?
            next new Error 'notifications must have a state'
        else
            notif = req.body.notificationsState
            notif = notif and notif isnt 'false'
            clearance = path[0].clearance or []
            for r in clearance when r.key is rule.key
                rule.notifications = r.notifications = notif
                folder.updateAttributes clearance: clearance, (err) ->
                    if err? then next err
                    else res.send 201

module.exports.publicList = (req, res, next) ->
    folder = req.folder

    # if the page is requested by the user
    if req.accepts('html, json') is 'html'
        errortemplate = (err) ->
            err = new Error 'File not found'
            err.status = 404
            err.template =
                name: '404'
                params:
                    localization: require '../lib/localization_manager'
                    isPublic: req.url.indexOf('public') isnt -1
            next err

        sharing.limitedTree folder, req, (path, rule) ->
            authorized = path.length isnt 0
            return errortemplate() unless authorized
            key = "#{folder.path}/#{folder.name}"
            async.parallel [
                (cb) -> CozyInstance.getLocale cb
            ], (err, results) ->
                return errortemplate err if err
                [lang] = results

                publicKey = req.query.key or ""
                imports = """
                    window.rootFolder = #{JSON.stringify folder};
                    window.locale = "#{lang}";
                    window.tags = [];
                    window.canUpload = #{rule.perm is 'rw'}
                    window.publicNofications = #{rule.notifications or false}
                    window.publicKey = "#{publicKey}"
                """

                try
                    html = jade.renderFile template, {imports}
                    res.send html
                catch err
                    errortemplate err
    else
        # ajax call to retrieve folder information
        module.exports.find req, res, next
