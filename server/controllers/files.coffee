File = require '../models/file'
fs = require 'fs'

## Helpers ##

findFile = (id, callback) ->
    File.find id, (err, file) =>
        if err or not file
            callback "File not found"
        else
            callback null, file 

## Actions ##

module.exports.all = (req, res) ->
    File.all (err, files) ->
        if err
            res.send error: true, msg: "Server error occured", 500
        else
            res.send files

module.exports.create = (req, res) ->
    file = req.files["file"]
    File.create req.body, (err, newfile) =>
        if err
            res.send error: true, msg: "Server error while creating file.", 500
        else
            newfile.attachFile file.path, {"name": file.name}, (err) ->
                if err
                    console.log "[Error]: " + err
                fs.unlink file.path, (err) ->
                    if err
                        console.log 'Could not delete', file.path
                    res.send newfile, 200

module.exports.find = (req, res) ->
     findFile req.params.id, (err, file) ->
        if err
            res.send error: true, msg: err, 404
        else
            res.send file

module.exports.getAttachment = (req, res) ->
    id = req.params.id
    findFile id, (err, file) =>
        if err
            res.send error: true, msg: err, 404
        else
            name = req.params.name
            res.setHeader 'Content-Disposition' , "inline"
            res.setHeader 'content-type' , "mime/type"
            stream = file.getFile name, (err, resp, body) =>
                if err
                    res.send error: true, msg: err, 500
            
            res.setHeader 'content-type' , "mime/type"
            stream.setHeader 'content-type' , "mime/type"
            stream.pipe(res)

module.exports.destroy = (req, res) ->
    findFile req.params.id, (err, file) ->
        if err
            res.send error: true, msg: err, 404
        else
            file.destroy (err) ->
                if err
                    compound.logger.write err
                    res.send error: 'Cannot destroy file', 500
                else
                    res.send success: 'File succesfuly deleted', 200