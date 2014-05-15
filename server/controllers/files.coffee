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


# Put right headers in response, then stream file to the response.
processAttachement = (req, res, next, download) ->
    id = req.params.id
    file = req.file

    if download
        contentHeader = "attachment; filename=#{file.name}"
    else
        contentHeader = "inline"
    res.setHeader 'Content-Disposition', contentHeader

    stream = file.getBinary "file", (err, resp, body) =>
        next err if err
    stream.pipe res


updateParentModifDate = (file, callback) ->
    Folder.byFullPath key: file.path, (err, parents) =>
        if err
            callback err
        else if parents.length > 0
            parent = parents[0]
            parent.lastModification = moment().toISOString()
            parent.save callback
        else
            callback()


getFileClass = (file) ->
    switch file.type.split('/')[0]
        when 'image' then fileClass = "image"
        when 'application' then fileClass = "document"
        when 'text' then fileClass = "document"
        when 'audio' then fileClass = "music"
        when 'video' then fileClass = "video"
        else
            fileClass = "file"
    fileClass


module.exports.fetch = (req, res, next, id) ->
    File.request 'all', key: id, (err, file) ->
        if err or not file or file.length is 0
            if err
                next err
            else
                res.send error:true, msg: 'File not found', 404
        else
            req.file = file[0]
            next()


## Actions ##


module.exports.find = (req, res) ->
    res.send req.file


module.exports.all = (req, res, next) ->
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

        fullPath = "#{req.body.path}/#{req.body.name}"
        File.byFullPath key: fullPath, (err, sameFiles) =>
            if sameFiles.length > 0
                res.send error:true, msg: "This file already exists", 400
            else
                file = req.files["file"]
                now = moment().toISOString()
                fileClass = getFileClass file

                # calculate metadata
                data =
                    name: req.body.name
                    path: req.body.path
                    creationDate: now
                    lastModification: now
                    mime: file.type
                    size: file.size
                    tags: []
                    class: fileClass

                createFile = ->
                    File.createNewFile data, file, (err, newfile) =>
                        who = req.guestEmail or 'owner'
                        sharing.notifyChanges who, newfile, (err) ->
                            console.log err if err
                            res.send newfile, 200

                # find parent folder
                Folder.byFullPath key: data.path, (err, parents) =>
                    if parents.length > 0
                        # inherit parent folder tags and update its last
                        # modification date
                        parent = parents[0]
                        data.tags = parent.tags
                        parent.lastModification = now
                        parent.save (err) ->
                            if err then next err
                            else createFile()
                    else
                        createFile()


# There is two ways to modify a file:
# * change its tags: simple modification
# * change its name: it requires to check that no file has the same name, then
# it requires a new indexation.
module.exports.modify = (req, res, next) ->

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
        previousName = file.name
        newName = body.name
        isPublic = body.public
        newPath = "#{file.path}/#{newName}"

        fullPath = "#{req.body.path}/#{req.body.name}"
        File.byFullPath key: fullPath, (err, sameFiles) =>
            return next err if err

            modificationSuccess =  (err) ->
                log.raw err if err
                log.info "File name changed from #{previousName} " + \
                         "to #{newName}"
                res.send success: 'File successfully modified'

            if sameFiles.length > 0
                log.info "No modification: Name #{newName} already exists."
                res.send
                    error: true
                    msg: "The name is already in use.", 400
            else
                data =
                    name: newName
                    public: isPublic
                    lastModification: moment().toISOString()

                data.clearance = body.clearance if body.clearance
                file.updateAttributes data, (err) =>
                    if err
                        next new Error 'Cannot modify file'
                    else
                        updateParentModifDate file, (err) ->
                            log.raw err if err
                            file.index ["name"], modificationSuccess


module.exports.destroy = (req, res, next) ->
    file = req.file
    file.removeBinary "file", (err, resp, body) =>
        if err and err.toString('utf8').indexOf('not found') == -1
            log.error "Cannot Remove binary for #{file.id}"
            next err
        else
            file.destroy (err) =>
                if err
                    log.error "Cannot destroy document #{file.id}"
                    next err
                else
                    updateParentModifDate file, (err) ->
                        log.raw err if err
                        res.send success: 'File successfully deleted'


module.exports.getAttachment = (req, res, next) ->
    processAttachement req, res, next, false


module.exports.downloadAttachment = (req, res, next) ->
    processAttachement req, res, next, true


# Download by a guest can only be performed if the guest has the good rights.
module.exports.publicDownloadAttachment = (req, res, next) ->
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
module.exports.search = (req, res, next) ->
    sendResults = (err, files) ->
        if err then next err
        else res.send files

    query = req.body.id
    query = query.trim()

    if query.indexOf('tag:') isnt -1
        parts = query.split()
        parts = parts.filter (tag) -> tag.indexOf 'tag:' isnt -1
        tag = parts[0].split('tag:')[1]
        File.request 'byTag', key: tag, sendResults
    else
        File.search "*#{query}*", sendResults