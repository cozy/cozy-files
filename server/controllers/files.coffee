fs = require 'fs'
async = require 'async'
moment = require 'moment'

File = require '../models/file'
Folder = require '../models/folder'
sharing = require '../helpers/sharing'
pathHelpers = require '../helpers/path'

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
            available = pathHelpers.checkIfPathAvailable req.body, files
            if not available
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

    log.info "File modification of #{req.file.name}..."
    file = req.file
    body = req.body

    if body.tags and (Array.isArray body.tags) and
       file.tags?.toString() isnt body.tags?.toString()
        tags = body.tags
        tags = tags.filter (tag) -> typeof tag is 'string'
        file.updateAttributes tags: tags, (err) =>
            if err
                next new Error "Cannot change tags: #{err}"
            else
                log.info "Tags changed for #{file.name}: #{tags}"
                res.send success: 'Tags successfully changed', 200

    else if not body.name or body.name is ""
        log.info "No arguments, no modification performed for #{req.file.name}"
        next new Error "Invalid arguments, name should be specified."

    else
        newName = body.name
        isPublic = body.public
        newPath = "#{file.path}/#{newName}"

        File.all (err, files) =>

            modificationSuccess =  (err) ->
                if err
                    next new Error  "Error indexing: #{err}"
                else
                    log.info "File name changed from #{file.name} to #{newName}"
                    res.send success: 'File successfully modified'

            available = pathHelpers.checkIfPathAvailable file, files, file.id
            if not available
                log.info "No modification: Name #{newName} already exists."
                res.send
                    error: true
                    msg: "The name is already in use.", 400
            else
                data =
                     name: newName
                     public: isPublic
                data.clearance = body.clearance if body.clearance
                file.updateAttributes data, (err) =>
                    if err
                        next new Error 'Cannot modify file'
                    else
                        file.index ["name"], modificationSuccess


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


# Download by a guest can only be performed if the guest has the good rights.
module.exports.publicDownloadAttachment = (req, res) ->
    sharing.checkClearance req.file, req, (authorized) ->
        if not authorized then res.send 404
        else processAttachement req, res, true


# Creation by a guest. The creation is performed only if the guest has the good
# rights.
module.exports.publicCreate = (req, res, next) ->
    file = new File req.body
    sharing.checkClearance file, req, 'w', (authorized, rule) ->
        if not rule then res.send 401
        else
            req.guestEmail = rule.email
            req.guestId = rule.contactid
            module.exports.create req, res, next


# Check if the research should be performed on tag or not.
# For tag, it will use the Data System request. Else it will use the Cozy
# Indexer.
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
        parts = parts.filter (tag) -> tag.indexOf 'tag:' isnt -1
        tag = parts[0].split('tag:')[1]
        File.request 'byTag', key: tag, sendResults
    else
        File.search "*#{query}*", sendResults
