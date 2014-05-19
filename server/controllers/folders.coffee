
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
                    params: localization: require '../lib/localization_manager'
            next err
        else
            req.folder = folder[0]
            next()


updateParentModifDate = (folder, callback) ->
    Folder.byFullPath key: folder.path, (err, parents) =>
        if err
            callback err
        else if parents.length > 0
            parent = parents[0]
            parent.lastModification = moment().toISOString()
            parent.save callback
        else
            callback()


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
                cb null, folder.path + '/' + folder.name

## Actions ##

# New folder creation operations:
# * Check if given name is valid
# * Check if folder already exists
# * Tag folder with parent folder tags
# * Create Folder and index its name
# * Send notification if required
module.exports.create = (req, res, next) ->
    folder = req.body
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
    Folder.getParents (err, folders) =>
        if err then next err
        else
            res.send parents, 200


module.exports.modify = (req, res, next) ->
    folderToModify = req.folder

    if (not req.body.name?) and (not req.body.public?) and (not req.body.tags?)
        return res.send error: true, msg: "Data required", 400

    newName = req.body.name
    isPublic = req.body.public
    oldPath = "#{folderToModify.path}/#{folderToModify.name}/"
    newPath = "#{folderToModify.path}/#{newName}/"
    newTags = req.body.tags or []
    newTags = newTags.filter (tag) -> typeof tag is 'string'

    oldRealPath = "#{folderToModify.path}/#{folderToModify.name}"
    newRealPath = "#{folderToModify.path}/#{newName}"

    updateIfIsSubFolder = (file, cb) ->

        if "#{file.path}/".indexOf(oldPath) is 0
            modifiedPath = file.path.replace oldRealPath, newRealPath

            # add new tags from parent, keeping the old ones
            oldTags = file.tags
            tags = [].concat(oldTags)
            for tag in newTags
                if tags.indexOf tag is -1
                    tags.push tag

            log.debug tags

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
            public: isPublic
            tags: newTags
            lastModification: moment().toISOString()

        data.clearance = req.body.clearance if req.body.clearance

        folderToModify.updateAttributes data, (err) =>
            return next err if err

            updateParentModifDate folderToModify, (err) ->
                log.raw err if err

                folderToModify.index ["name"], (err) ->
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
        if (file.path.indexOf(directory) is 0)
            if file.binary
                file.removeBinary "file", (err) ->
                    if err
                        cb err
                    else
                        file.destroy cb
            else
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
                    updateParentModifDate currentFolder, (err) ->
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
    getFolderPath req.body.id, (err, key) ->
        if err? then next err
        else
            async.parallel [
                (cb) -> Folder.byFolder key: key, cb
                (cb) -> File.byFolder key: key, cb
            ], (err, results) ->

                if err? then next err
                else
                    [folders, files] = results
                    content = folders.concat files
                    res.send 200, content

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
            res.send 200, content

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


module.exports.publicList = (req, res, next) ->
    folder = req.folder

    errortemplate = (err) ->
        err = new Error 'File not found'
        err.status = 404
        err.template =
            name: '404'
            params: localization: require '../lib/localization_manager'
        next err

    sharing.limitedTree folder, req, (path, rule) ->
        authorized = path.length isnt 0
        return res.send 404 unless authorized
        key = "#{folder.path}/#{folder.name}"
        async.parallel [
            (cb) -> CozyInstance.getLocale cb
            (cb) -> Folder.byFolder key:key, cb
            (cb) -> File.byFolder key:key, cb
            (cb) ->
                # change the notifications setting
                return cb() if req.query.notifications is undefined

                notif = req.query.notifications
                notif = notif and notif isnt 'false'
                clearance = path[0].clearance or []
                for r in clearance when r.key is rule.key
                    rule.notifications = r.notifications = notif
                folder.updateAttributes clearance: clearance, cb

        ], (err, results) ->
            return errortemplate err if err
            [lang, folders, files] = results

            translations = try require '../../client/app/locales/' + lang
            catch e then {}
            translate = (text) -> translations[text] or text

            #format date & size
            files = files.map (file) ->

                file = file.toJSON()

                file.lastModification = new Date(file.lastModification)
                .toISOString().split('T').join(' ').split('.')[0]

                file.size = if file.size > MB
                    (parseInt(file.size) / MB).toFixed(1) + translate "MB"
                else if file.size > KB
                    (parseInt(file.size) / KB).toFixed(1) + translate "KB"
                else
                    file.size + translate "B"

                return file

            locals = {
                path
                files
                folders
                lang
                canupload: rule.perm is 'rw'
                notifications: rule.notifications or false
                keyquery: if req.query.key? then "?key=#{req.query.key}" else ""
                t: translate
            }

            try
                html = jade.renderFile publicfoldertemplate, locals
                res.send html
            catch err
                errortemplate err


module.exports.publicZip = (req, res, next) ->
    errortemplate = (err) ->
        err = new Error 'File not found'
        err.status = 404
        err.template =
            name: '404'
            params: localization: require '../lib/localization_manager'
        next err

    sharing.checkClearance req.folder, req, (authorized) ->
        if not authorized then res.send 404
        else module.exports.zip req, res


module.exports.publicCreate = (req, res, next) ->
    folder = new Folder req.body
    sharing.checkClearance folder, req, 'w', (authorized) ->
        if not authorized then res.send 401
        else module.exports.create req, res, next
