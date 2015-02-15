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
cozydb = require 'cozydb'

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
folderParent = {}
timeout = null
module.exports.create = (req, res, next) ->
    clearTimeout(timeout) if timeout?
    folder = req.body
    folder.path = normalizePath folder.path

    if (not folder.name) or (folder.name is "")
        next new Error "Invalid arguments"
    else
        Folder.all (err, folders) =>
            available = pathHelpers.checkIfPathAvailable folder, folders
            if not available
                res.send code: 'EEXISTS', error: true, msg: "This folder already exists", 400
            else
                fullPath = folder.path
                parents = folders.filter (tested) ->
                    fullPath is tested.getFullPath()

                now = moment().toISOString()
                createFolder = ->
                    folder.creationDate = now
                    folder.lastModification = now

                    Folder.createNewFolder folder, (err, newFolder) ->
                        resetTimeout()
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
                    folderParent[parent.name] = parent
                    #parent.save (err) ->
                    #    if err then next err
                    #else
                    createFolder()
                else
                    folder.tags = []
                    createFolder()

# After 1 minute of inactivity, update parents
resetTimeout = () =>
    clearTimeout(timeout) if timeout?
    timeout = setTimeout () =>
        updateParents()
    , 60 * 1000


# Save in RAM lastModification date for parents
# Update folder parent once all files are uploaded
updateParents = () ->
    errors = {}
    for name in Object.keys(folderParent)
        folder = folderParent[name]
        folder.save (err) ->
            errors[folder.name] = err if err?
    folderParent = {}

module.exports.find = (req, res, next) ->
    Folder.injectInheritedClearance [req.folder], (err, folders) ->
        res.send folders[0]

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

        if file.path?.indexOf(oldRealPath) is 0
            modifiedPath = file.path.replace oldRealPath, newRealPath

            # add new tags from parent, keeping the old ones
            oldTags = file.tags
            tags = [].concat oldTags
            for tag in newTags
                tags.push tag if tags.indexOf(tag) is -1

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

    # get all files and folders to determine the children of the deleted folder
    async.parallel [
        (cb) -> Folder.all cb
        (cb) -> File.all cb
    ], (err, elements) ->
        if err? then return next err

        [folders, files] = elements

        # get the path of files and folders to delete
        elements = files.concat folders
        elementsToDelete = elements.filter (element) ->
            pathToTest = "#{element.path}/"
            return pathToTest.indexOf("#{directory}/") is 0

        destroyElement = (element, cb) ->
            if element.binary?
                element.destroyWithBinary cb
            else
                element.destroy cb

        async.each elementsToDelete, destroyElement, (err) ->
            if err? then next err
            else
                currentFolder.destroy (err) ->
                    if err? then next err
                    else
                        currentFolder.updateParentModifDate (err) ->
                            log.raw err if err?
                            res.send 204

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

    isPublic = req.url.indexOf('/public/') isnt -1

    getFolderPath req.body.id, (err, key, folder) ->
        if err? then next err
        else
            async.parallel [

                # Retrieves the folders and inject the inherited clearance
                (cb) -> Folder.byFolder key: key, (err, folders) ->
                    # if it's a request from a guest, we limit the results
                    unless isPublic
                        Folder.injectInheritedClearance folders, cb
                    else
                        cb null, folders

                # Retrieves the files and inject the inherited clearance
                (cb) -> File.byFolder key: key, (err, files) ->
                    # if it's a request from a guest, we limit the results
                    unless isPublic
                        File.injectInheritedClearance files, cb
                    else
                        cb null, files
                (cb) ->
                    if req.body.id is "root"
                        cb null, []
                    else
                        # if it's a request from a guest, we limit the results
                        if isPublic
                            onResult = (parents, rule) ->
                                # limitedTree adds the current folder as parent
                                # so we need to remove it
                                parents.pop()
                                cb null, parents
                            sharing.limitedTree folder, req, onResult
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
                # Retrieves the folders and inject the inherited clearance
                (cb) -> Folder.request 'byTag', key: tag, (err, folders) ->
                    Folder.injectInheritedClearance folders, cb

                # Retrieves the files and inject the inherited clearance
                (cb) -> File.request 'byTag', key: tag, (err, files) ->
                    File.injectInheritedClearance files, cb
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

                # if there is a key we must filter the results so it doesn't
                # display unshared files and folders
                if key?
                    isAuthorized = (element, callback) ->
                        sharing.checkClearance element, req, (authorized) ->
                            callback authorized and element.clearance isnt 'public'

                    async.filter content, isAuthorized, (results) ->
                        sendResults results
                else
                    sendResults content


# List files contained in the folder and return them as a zip archive.
module.exports.zip = (req, res, next) ->
    folder = req.folder
    archive = archiver 'zip'

    if folder?
        key = "#{folder.path}/#{folder.name}"
        zipName = folder.name?.replace /\W/g, ''

    # if there is no folder, the target is root
    else
        key = ""
        zipName = 'cozy-files'

    # Request can limit the ZIP content to some elements only
    if req.body?.selectedPaths?
        selectedPaths = req.body.selectedPaths.split ';'
    else
        selectedPaths = []

    # Download file and pipe the result in the archiver.
    addToArchive = (file, cb) ->
        laterStream = file.getBinary "file", (err) ->
            if err
                log.error """
An error occured while adding a file to archive. File: #{file.name}
"""
                log.raw err
                cb()

        name = "#{file.path.replace(key, "")}/#{file.name}"
        laterStream.on 'ready', (stream) ->
            archive.append stream, name: name
            cb()

    # Build zip from file list and pip the result in the response.
    makeZip = (zipName, files) ->

        # Start the streaming.
        archive.pipe res

        # Arbort archiving process when request is closed.
        req.on 'close', ->
            archive.abort()

        # Set headers describing the final zip file.
        disposition = "attachment; filename=\"#{zipName}.zip\""
        res.setHeader 'Content-Disposition', disposition
        res.setHeader 'Content-Type', 'application/zip'

        async.eachSeries files, addToArchive, (err) ->
            if err then next err
            else
                archive.finalize (err, bytes) ->
                    if err then next err


    # Grab all files and files of children folders
    File.byFullPath startkey: "#{key}/", endkey: "#{key}/\ufff0", (err, files) ->
        if err then next err
        else
            # Only keeps files that have been selected
            files = files.filter (file) ->
                fullPath = "#{file.path}/#{file.name}"
                path = "#{file.path}/"

                fileMatch = selectedPaths.indexOf(fullPath) isnt -1
                subFolderMatch = selectedPaths.indexOf(path) isnt -1

                # Selects the file if it has been selected OR its parent has
                # been selected (or parent of its parent...) OR if no file has
                # been selected
                return selectedPaths.length is 0 or fileMatch or subFolderMatch

            # Build zip file.
            makeZip zipName, files


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
    if ~req.accepts(['html', 'json']).indexOf 'html'
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
            cozydb.api.getCozyLocale (err, lang) ->
                return errortemplate err if err

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
