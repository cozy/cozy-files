File = require '../models/file'
fs = require 'fs'
async = require 'async'

## Helpers ##

findFile = (id, callback) ->
    File.find id, (err, file) =>
        if err or not file
            callback "File not found"
        else
            callback null, file

processAttachement = (req, res, download) ->
    id = req.params.id
    findFile id, (err, file) =>
        if err
            res.send error: true, msg: err, 404
        else
            res.setHeader 'Content-Disposition', (if download then "attachment; filename=" + file.name else "inline")
            stream = file.getBinary "file", (err, resp, body) =>
                if err
                    res.send error: true, msg: err, 500
            stream.pipe(res)

## Actions ##

module.exports.all = (req, res) ->
    File.all (err, files) ->
        if err
            res.send error: true, msg: "Server error occured: #{err}", 500
        else
            res.send files

module.exports.create = (req, res) ->
    console.log "files.create"
    if not req.body.name or req.body.name == ""
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

                    # create the file
                    File.create req.body, (err, newfile) =>
                        if err
                            res.send error: true, msg: "Server error while creating file; #{err}", 500
                        else
                            newfile.attachBinary file.path, {"name": "file"}, (err) ->
                                if err
                                    console.log "[Error]: " + err
                                    res.send error: true, msg: "Error attaching binary: #{err}", 500
                                else
                                    newfile.index ["name"], (err) ->
                                        if err
                                            res.send error: true, msg: "Error indexing: #{err}", 500
                                        else
                                            fs.unlink file.path, (err) ->
                                                if err
                                                    console.log 'Could not delete', file.path
                                                    res.send error: true, msg: "Error removing uploaded file: #{err}", 500
                                                else
                                                    res.send newfile, 200

module.exports.find = (req, res) ->
     findFile req.params.id, (err, file) ->
        if err
            res.send error: true, msg: err, 404
        else
            res.send file

module.exports.modify = (req, res) ->
    if not req.body.name or req.body.name == ""
        res.send error: true, msg: "No filename specified", 404
    else
        findFile req.params.id, (err, fileToModify) ->
            if err
                res.send error: true, msg: err, 404
            else
                newName = req.body.name
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
                            fileToModify.updateAttributes name: newName, (err) =>
                                if err
                                    console.log err
                                    res.send error: 'Cannot modify file', 500
                                else
                                    fileToModify.index ["name"], (err) ->
                                        if err
                                            res.send error: true, msg: "Error indexing: #{err}", 500
                                        else
                                            res.send success: 'File successfully modified', 200

module.exports.destroy = (req, res) ->
    findFile req.params.id, (err, file) ->
        if err
            res.send error: true, msg: err, 404
        else
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

module.exports.search = (req, res, next) ->
    File.search "*#{req.body.id}*", (err, files) ->
        if err
            next err
        else
            res.send files
