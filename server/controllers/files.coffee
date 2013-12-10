File = require '../models/file'
fs = require 'fs'
async = require 'async'
MailHelper = require "../mails/mail_helper"
mails = new MailHelper()


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
        if err or not file
            next new Error "File not found" if err
            return res.error 404, 'File not found' if not file
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

module.exports.create = (req, res) ->
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

                    # create the file
                    File.create req.body, (err, newfile) =>
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
    if not req.body.name or req.body.name is ""
        res.send error: true, msg: "No filename specified", 400
    else
        fileToModify = req.file
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

module.exports.search = (req, res) ->
    File.search "*#{req.body.id}*", (err, files) ->
        if err
            res.send error: true, msg: err, 500
        else
            console.log files
            res.send files

module.exports.getPublicLink = (req, res) ->
    file = req.file

    # send the email and get url
    mails.getFileUrl file, (err, url) ->
        if err
            console.log err
            res.send error: true, msg: err, 500
        else
            res.send url: url, 200

module.exports.sendPublicLinks = (req, res) ->
    file = req.file
    users = req.body.users

    # send the email and get url
    mails.sendPublicLinks file, users, (err, url) ->
        if err
            console.log err
            res.send error: true, msg: err, 500
        else
            res.send url: url, 200
