fs = require 'fs'
async = require 'async'
moment = require 'moment'

File = require '../models/file'
Folder = require '../models/folder'
sharing = require '../helpers/sharing'

log = require('printit')
    prefix: 'files'


## Helpers ##

processAttachement = (req, res, download) ->
    id = req.params.id
    file = req.file
    res.setHeader 'Content-Disposition', (if download then "attachment; filename=" + file.name else "inline")
    stream = file.getBinary "file", (err, resp, body) =>
        next err if err
    stream.pipe res

module.exports.fetch = (req, res, next, id) ->
    File.request 'all', key: id, (err, file) ->
        if err or not file or file.length is 0
            if err
                next new Error "File not found"
            else
                res.send error:true, msg: 'File not found', 404
        else
            req.file = file[0]
            next()


## Actions ##

module.exports.all = (req, res) ->
    File.all (err, files) ->
        if err
            next err
        else
            res.send files

# Prior to file creation it ensures that all parameters are correct and that no
# file already exists with the same name. Then it builds the file document from
# given information and uploaded file metadata. Once done, it performs all
# database operation and index the file name. Finally, it tags the file if the
# parent folder is tagged.
module.exports.create = (req, res, next) ->
    if not req.body.name or req.body.name is ""
        next new Error "Invalid arguments"
    else
        File.all (err, files) =>
            avalailable = true
            fullPath = "#{req.body.path}/#{req.body.name}"
            for fileDoc in files
                fileFullPath = "#{fileDoc.path}/#{fileDoc.name}"
                available = false if fullPath is fileFullPath

            if available
                res.send error:true, msg: "This file already exists", 400
            else
                file = req.files["file"]
                now = moment().toISOString()

                # calculate metadata
                data                  = {}
                data.name             = req.body.name
                data.path             = req.body.path
                data.creationDate     = now
                data.lastModification = now
                data.mime             = file.type
                data.size             = file.size
                switch file.type.split('/')[0]
                    when 'image' then data.class = "image"
                    when 'application' then data.class = "document"
                    when 'text' then data.class = "document"
                    when 'audio' then data.class = "music"
                    when 'video' then data.class = "video"
                    else
                        data.class = "file"

                # find parent folder
                Folder.all (err, folders) =>
                    return callback err if err

                    fullPath = data.path
                    parents = folders.filter (tested) ->
                        fullPath is tested.getFullPath()

                    # inherit its tags
                    if parents.length
                        parent = parents[0]
                        data.tags = parent.tags
                    else
                        data.tags = []

                    # create the file
                    File.createNewFile data, file, (err, newfile) =>
                        who = req.guestEmail or 'owner'
                        sharing.notifyChanges who, newfile, (err) ->
                            # ignore this err
                            console.log err if err
                            res.send newfile, 200


module.exports.find = (req, res) ->
    res.send req.file


module.exports.modify = (req, res) ->
    validRequest = false
    if req.body.name and req.body.name.trim() isnt ""
        validRequest = true
        fileToModify = req.file
        newName = req.body.name
        isPublic = req.body.public
        newPath = fileToModify.path + '/' + newName

        # test if the filename is available
        hasntTheSamePathOrIsTheSame = (file, cb) ->
            if (fileToModify.id is file.id)
                cb true
            else
                cb (newPath isnt (file.path + '/' + file.name))

        File.all (err, files) =>

            async.every files, hasntTheSamePathOrIsTheSame, (available) ->
                if not available
                    res.send error: true, msg: "The name already in use", 400
                else
                    data =
                         name: newName
                         public: isPublic
                    data.clearance = req.body.clearance if req.body.clearance
                    fileToModify.updateAttributes data, (err) =>
                        if err
                            console.log err
                            res.send error: 'Cannot modify file', 500
                        else
                            fileToModify.index ["name"], (err) ->
                                if err
                                    res.send error: true, msg: "Error indexing: #{err}", 500
                                else
                                    res.send success: 'File successfully modified', 200

    if req.body.tags and Array.isArray req.body.tags
        validRequest = true
        file = req.file
        tags = req.body.tags
        tags = tags.filter (e) -> typeof e is 'string'
        file.updateAttributes tags: tags, (err) =>
            if err
                console.log err
                res.send error: 'Cannot change tags', 500
            else
                res.send success: 'Tags successfully changed', 200

    if not validRequest
        res.send error: true, msg: "No data specified", 400


module.exports.destroy = (req, res) ->
    file = req.file
    file.removeBinary "file", (err, resp, body) =>
        file.destroy (err) =>
            if err
                console.log err
                res.send error: 'Cannot delete file', 500
            else
                res.send success: 'File successfully deleted', 200


module.exports.getAttachment = (req, res) ->
    processAttachement req, res, false


module.exports.downloadAttachment = (req, res) ->
    processAttachement req, res, true


module.exports.publicDownloadAttachment = (req, res) ->
    sharing.checkClearance req.file, req, (authorized) ->
        if not authorized then res.send 404
        else processAttachement req, res, true


module.exports.publicCreate = (req, res, next) ->
    toCreate = new File(req.body)
    sharing.checkClearance toCreate, req, 'w', (authorized, rule) ->
        if not rule then res.send 401
        else
            req.guestEmail = rule.email
            req.guestId = rule.contactid
            module.exports.create req, res, next


module.exports.search = (req, res) ->
    sendResults = (err, files) ->
        if err
            next err
        else
            res.send files

    query = req.body.id
    query = query.trim()

    if query.indexOf('tag:') isnt -1
        parts = query.split()
        parts = parts.filter (e) -> e.indexOf 'tag:' isnt -1
        tag = parts[0].split('tag:')[1]
        File.request 'byTag', key: tag, sendResults
    else
        File.search "*#{query}*", sendResults
