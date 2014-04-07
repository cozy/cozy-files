File = require '../models/file'
fs = require 'fs'
async = require 'async'
sharing = require '../helpers/sharing'


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

module.exports.create = (req, res, next) ->
    if not req.body.name or req.body.name is ""
        res.send error: true, msg: "Invalid arguments", 500
    else
        File.all (err, files) =>

            hasntTheSamePath = (file, cb) ->
                cb ((req.body.path + '/' + req.body.name) isnt (file.path + '/' + file.name))

            # check that the name is not already taken
            async.every files, hasntTheSamePath, (available) ->
                if not available
                    res.send error:true, msg: "This file already exists", 400
                else
                    file = req.files["file"]

                    # calculate metadata
                    data                  = {}
                    data.name             = req.body.name
                    data.path             = req.body.path
                    data.lastModification = req.body.lastModification
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

                    # create the file
                    File.create data, (err, newfile) =>
                        if err
                            next new Error "Server error while creating file; #{err}"
                        else
                            newfile.attachBinary file.path, {"name": "file"}, (err) ->
                                if err
                                    next new Error "Error attaching binary: #{err}"
                                else
                                    newfile.index ["name"], (err) ->
                                        if err
                                            next new Error "Error indexing: #{err}"
                                        else
                                            fs.unlink file.path, (err) ->
                                                if err
                                                    next new Error "Error removing uploaded file: #{err}"
                                                else
                                                    res.send newfile, 200

module.exports.find = (req, res) ->
    res.send req.file

module.exports.modify = (req, res) ->
    ok = false
    if req.body.name and req.body.name.trim() isnt ""
        ok = true
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
        ok = true
        file = req.file
        tags = req.body.tags
        console.log tags
        file.updateAttributes tags: tags, (err) =>
            if err
                console.log err
                res.send error: 'Cannot change tags', 500
            else
                res.send success: 'Tags successfully changed', 200

    if not ok
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

module.exports.search = (req, res) ->
    File.search "*#{req.body.id}*", (err, files) ->
        if err
            res.send error: true, msg: err, 500
        else
            res.send files
