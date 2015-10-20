fs = require 'fs'
async = require 'async'
moment = require 'moment'
crypto = require 'crypto'
multiparty = require 'multiparty'
mime = require 'mime'
log = require('printit')
    prefix: 'files'

cozydb = require 'cozydb'
File = require '../models/file'
Folder = require '../models/folder'
feed = require '../lib/feed'
sharing = require '../helpers/sharing'
pathHelpers = require '../helpers/path'
{normalizePath, getFileClass} = require '../helpers/file'

baseController = new cozydb.SimpleController
    model: File
    reqProp: 'file'
    reqParamID: 'fileid'


## FOR TESTS - TO BE DELETED ##
module.exports.destroyBroken = (req, res) ->
    res.send 400,
        error: true
        msg: "Deletion error for tests"


## Helpers ##


module.exports.fetch = (req, res, next, id) ->
    File.request 'all', key: id, (err, file) ->
        if err or not file or file.length is 0
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
            req.file = file[0]
            next()


## Actions ##


module.exports.find = baseController.send
module.exports.all = baseController.listAll

# Perform download as an inline attachment.
sendBinary = baseController.sendBinary
    filename: 'file'

module.exports.getAttachment = (req, res, next) ->

    # Prevent server from stopping if the download is very slow.
    isDownloading = true
    do keepAlive = ->
        if isDownloading
            feed.publish 'usage.application', 'files'
            setTimeout keepAlive, 60 * 1000

    # Configure headers so clients know they should read and not download.
    encodedFileName = encodeURIComponent req.file.name
    res.setHeader 'Content-Disposition', """
        inline; filename*=UTF8''#{encodedFileName}
    """

    # Tell when the download is over in order to stop the keepAlive mechanism.
    res.on 'close', -> isDownloading = false
    res.on 'finish', -> isDownloading = false

    sendBinary req, res, next


# Perform download as a traditional attachment.
module.exports.downloadAttachment = (req, res, next) ->

    # Prevent server from stopping if the download is very slow.
    isDownloading = true
    do keepAlive = ->
        if isDownloading
            feed.publish 'usage.application', 'files'
            setTimeout keepAlive, 60 * 1000


    # Configure headers so clients know they should download, and that they
    # can make up the file name.
    encodedFileName = encodeURIComponent req.file.name
    res.setHeader 'Content-Disposition', """
        attachment; filename*=UTF8''#{encodedFileName}
    """

    # Tell when the download is over in order to stop the keepAlive mechanism.
    res.on 'close', -> isDownloading = false
    res.on 'finish', -> isDownloading = false

    sendBinary req, res, next


# Prior to file creation it ensures that all parameters are correct and that no
# file already exists with the same name. Then it builds the file document from
# given information and uploaded file metadata. Once done, it performs all
# database operation and index the file name. Finally, it tags the file if the
# parent folder is tagged.
folderParent = {}
timeout = null

# Helpers functions of upload process

# check if an error is storage related
isStorageError = (err) ->
    return err.toString().indexOf('enough storage') isnt -1

# After 1 minute of inactivity, update parents
resetTimeout = ->
    clearTimeout(timeout) if timeout?
    timeout = setTimeout updateParents, 60 * 1000


# Save in RAM lastModification date for parents
# Update folder parent once all files are uploaded
updateParents = ->
    errors = {}
    for name in Object.keys(folderParent)
        folder = folderParent[name]
        folder.save (err) ->
            errors[folder.name] = err if err?
    folderParent = {}


confirmCanUpload = (data, req, next) ->

    # owner can upload.
    return next null unless req.public
    element = new File data
    sharing.checkClearance element, req, 'w', (authorized, rule) ->
        if authorized
            if rule?
                req.guestEmail = rule.email
                req.guestId = rule.contactid
            next()
        else
            err = new Error 'You cannot access this resource'
            err.status = 404
            err.template =
                name: '404'
                params:
                    localization: require '../lib/localization_manager'
                    isPublic: true
            next err


module.exports.create = (req, res, next) ->
    clearTimeout(timeout) if timeout?

    fields = {}

    # Parse given form to extract image blobs.
    form = new multiparty.Form()

    form.on 'part', (part) ->
        # Get field, form is processed one way, be sure that fields are sent
        # before the file.
        # Parts are processed sequentially, so the data event should be
        # processed before reaching the file part.
        unless part.filename?
            fields[part.name] = ''
            part.on 'data', (buffer) ->
                fields[part.name] = buffer.toString()
            return

        # We assume that only one file is sent.
        # we do not write a subfunction because it seems to load the whole
        # stream in memory.
        name = fields.name
        path = fields.path
        lastModification = moment(new Date(fields.lastModification))
        lastModification = lastModification.toISOString()
        overwrite = fields.overwrite
        upload = true
        canceled = false
        uploadStream = null

        # we have no name for this file, give up
        if not name or name is ""
            err = new Error "Invalid arguments: no name given"
            err.status = 400
            return next err

        # while this upload is processing
        # we send usage.application to prevent auto-stop
        # and we defer parents lastModification update
        keepAlive = ->
            if upload
                feed.publish 'usage.application', 'files'
                setTimeout keepAlive, 60*1000
                resetTimeout()

        # if anything happens after the file is created
        # we need to destroy it
        rollback = (file, err) ->
            canceled = true
            file.destroy (delerr) ->
                # nothing more we can do with delerr
                log.error delerr if delerr
                if isStorageError err
                    res.send
                        error: true
                        code: 'ESTORAGE'
                        msg: "modal error size"
                    , 400
                else
                    next err

        attachBinary = (file) ->
            # request-json requires a path field to be set
            # before uploading
            part.path = file.name

            part.httpVersion = true # hack so form_data use length
            part.headers['content-length']?= part.byteCount

            checksum = crypto.createHash 'sha1'
            checksum.setEncoding 'hex'
            part.pause()
            part.pipe checksum
            metadata = name: "file"
            uploadStream = file.attachBinary part, metadata, (err) ->
                upload = false
                # rollback if there was an error
                return rollback file, err if err #and not canceled

                # TODO move everythin below in the model.
                checksum.end()
                checksum = checksum.read()

                # set the file checksum

                unless canceled

                    data =
                        checksum: checksum
                        uploading: false

                    file.updateAttributes data, (err) ->
                        # we ignore checksum storing errors
                        log.debug err if err

                        # index the file in cozy-indexer for fast search
                        file.index ["name"], (err) ->
                            # we ignore indexing errors
                            log.debug err if err

                            # send email or notification of file changed
                            who = req.guestEmail or 'owner'
                            sharing.notifyChanges who, file, (err) ->

                                # we ignore notification errors
                                log.debug err if err

                                # Retrieve binary metadat
                                File.find file.id, (err, file) ->
                                    log.debug err if err
                                    res.send file, 200

        now = moment().toISOString()

        # Check that the file doesn't exist yet.
        path = normalizePath path
        fullPath = "#{path}/#{name}"
        File.byFullPath key: fullPath, (err, sameFiles) ->
            return next err if err

            # there is already a file with the same name, give up
            if sameFiles.length > 0
                if overwrite
                    file = sameFiles[0]
                    attributes =
                        lastModification: lastModification
                        size: part.byteCount
                        mime: mime.lookup name
                        class: getFileClass part
                        uploading: true
                    return file.updateAttributes attributes, ->
                        # Ask for the data system to not run autostop
                        # while the upload is running.
                        keepAlive()

                        # Attach file in database.
                        attachBinary file
                else
                    upload = false
                    return res.send
                        error: true
                        code: 'EEXISTS'
                        msg: "This file already exists"
                    , 400

            # Generate file metadata.
            data =
                name: name
                path: normalizePath path
                creationDate: now
                lastModification: lastModification
                mime: mime.lookup name
                size: part.byteCount
                tags: []
                class: getFileClass part
                uploading: true

            # check if the request is allowed
            confirmCanUpload data, req, (err) ->
                return next err if err

                # find parent folder for updating its last modification
                # date and applying tags to uploaded file.
                Folder.byFullPath key: data.path, (err, parents) ->
                    return next err if err

                    # inherit parent folder tags and update its
                    # last modification date
                    if parents.length > 0
                        parent = parents[0]
                        data.tags = parent.tags
                        parent.lastModification = now
                        folderParent[parent.name] = parent

                    # Save file metadata
                    File.create data, (err, newFile) ->
                        return next err if err

                        # Ask for the data system to not run autostop
                        # while the upload is running.
                        keepAlive()

                        # If user stops the upload, the file is deleted.
                        err = new Error 'Request canceled by user'
                        res.on 'close', ->
                            log.info 'Upload request closed by user'
                            uploadStream.abort()

                        # Attach file in database.
                        attachBinary newFile

    form.on 'error', (err) ->
        log.error err

    form.parse req

module.exports.publicCreate = (req, res, next) ->
    req.public = true
    module.exports.create req, res, next

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
        file.updateAttributes tags: tags, (err) ->
            if err
                next new Error "Cannot change tags: #{err}"
            else
                log.info "Tags changed for #{file.name}: #{tags}"
                res.send success: 'Tags successfully changed', 200

    else if (not body.name or body.name is "") and not body.path?
        log.info "No arguments, no modification performed for #{req.file.name}"
        next new Error "Invalid arguments, name should be specified."

    # Case where path or name changed.
    else
        previousName = file.name
        newName = if body.name? then body.name else previousName
        previousPath = file.path
        body.path = normalizePath body.path if req.body.path?
        newPath = if body.path? then body.path else previousPath

        isPublic = body.public
        newFullPath = "#{newPath}/#{newName}"
        previousFullPath = "#{previousPath}/#{previousName}"

        File.byFullPath key: newFullPath, (err, sameFiles) ->
            return next err if err

            modificationSuccess =  (err) ->
                log.raw err if err
                log.info "Filechanged from #{previousFullPath} " + \
                         "to #{newFullPath}"
                res.send success: 'File successfully modified'

            if sameFiles.length > 0
                log.info "No modification: Name #{newName} already exists."
                res.send 400,
                    error: true
                    msg: "The name is already in use."
            else
                data =
                    name: newName
                    path: normalizePath newPath
                    public: isPublic

                data.clearance = body.clearance if body.clearance

                file.updateAttributes data, (err) ->
                    if err
                        next new Error 'Cannot modify file'
                    else
                        file.updateParentModifDate (err) ->
                            log.raw err if err
                            file.index ["name"], modificationSuccess


# Perform file removal and binaries removal.
module.exports.destroy = (req, res, next) ->
    file = req.file
    file.destroyWithBinary (err) ->
        if err
            log.error "Cannot destroy document #{file.id}"
            next err
        else
            file.updateParentModifDate (err) ->
                log.raw err if err
                res.send success: 'File successfully deleted'


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


###*
 * Returns thumb for given file.
 * there is a bug : when the browser cancels many downloads, some are not
 * cancelled, what leads to saturate the stack of threads and blocks the
 * download of thumbs.
 * Cf comments bellow to reproduce easily
###
module.exports.photoThumb = (req, res, next) ->
    which = if req.file.binary.thumb then 'thumb' else 'file'
    stream = req.file.getBinary which, (err) ->
        if err
            console.log err
            next(err)
            stream.on 'data', () ->
            stream.on 'end', () ->
            stream.resume()
            return

    req.on 'close', () ->
        stream.abort()

    res.on 'close', () ->
        stream.abort()

    stream.pipe res
###*
 * Returns "screens" (image reduced in ) for given file.
 * there is a bug : when the browser cancels many downloads, some are not
 * cancelled, what leads to saturate the stack of threads and blocks the
 * download of thumbs.
 * Cf comments bellow to reproduce easily
###
module.exports.photoScreen = (req, res, next) ->
    which = if req.file.binary.screen then 'screen' else 'file'
    stream = req.file.getBinary which, (err) ->
        if err
            console.log err
            next(err)
            stream.on 'data', () ->
            stream.on 'end', () ->
            stream.resume()
            return

    req.on 'close', () ->
        stream.abort()

    res.on 'close', () ->
        stream.abort()

    stream.pipe res
    ##
    # there is a bug : when the browser cancels many downloads, some are not
    # cancelled, what leads to saturate the stack of threads and blocks the
    # download of thumbs.
    # The code bellow makes it easy to reproduce the problem : just by delaying
    # the response, if you move the scrollbar in the browser, it will cancel
    # many photos...
    #
    # setTimeout(() ->
    #     stream = req.file.getBinary which, (err) ->
    #         if err
    #             console.log err
    #             next(err)
    #             stream.on 'data', () ->
    #             stream.on 'end', () ->
    #             stream.resume()
    #             return

    #     req.on 'close', () ->
    #         console.log "reQ.on close"
    #         stream.destroy()
    #         stream.abort()

    #     req.connection.on 'close', () ->
    #         console.log 'reQ.connection.on close'
    #         stream.destroy()
    #         stream.abort()

    #     req.on 'end', () ->
    #         console.log 'reQ.on end'
    #         stream.destroy()
    #         stream.abort()

    #     res.on 'close', () ->
    #         console.log "reS.on close"
    #         stream.abort()
    #         stream.destroy()
    #         stream.abort()

    #     res.connection.on 'close', () ->
    #         console.log 'reS.connection.on close'
    #         stream.destroy()
    #         stream.abort()

    #     res.on 'end', () ->
    #         console.log 'reS.on end'
    #         stream.destroy()
    #         stream.abort()

    #     stream.on 'close', () ->
    #         console.log 'stream.on close'
    #         stream.destroy()
    #         stream.abort()

    #     stream.pipe res
    # , 5000
    # )
    #
