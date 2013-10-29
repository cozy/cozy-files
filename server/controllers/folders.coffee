Folder = require '../models/folder'
File = require '../models/file'


## Helpers ##

findFolder = (id, callback) ->
    Folder.find id, (err, file) =>
        if err or not file
            callback "File not found"
        else
            callback null, file 

## Actions ##

module.exports.create = (req, res) ->
    newFolderFullPath = req.body.path + '/' + req.body.name
    Folder.all (err, folders) =>
        conflict = false
        for folder in folders
            fullPath = folder.path + '/' + folder.name
            if fullPath is newFolderFullPath
                conflict = true
                res.send error:true, msg: "This folder already exists", 400
        if not conflict
            Folder.create req.body, (err, newFolder) ->
                if err
                    res.send error: true, msg: "Server error while creating file.", 500
                else    
                    res.send newFolder, 200

module.exports.find = (req, res) ->
    findFolder req.params.id, (err, folder) ->
        if err
            res.send error: true, msg: err, 404
        else   
            res.send folder, 200

module.exports.findFiles = (req, res) ->
    if req.params.id is 'root'
        File.byFolder key: "" ,(err, files) ->
            if err
                res.send error: true, msg: "Server error occured", 500
            else
                res.send files, 200 
    else
        findFolder req.params.id, (err, folder) ->
            if err
                res.send error: true, msg: err, 404
            else
                File.byFolder key: folder.path + '/' + folder.name ,(err, files) ->
                    if err
                        res.send error: true, msg: "Server error occured", 500
                    else
                        res.send files, 200 


module.exports.findFolders = (req, res) ->
    if req.params.id is 'root'
        Folder.byFolder key: "" ,(err, folders) ->
            if err
                res.send error: true, msg: "Server error occured", 500
            else
                res.send folders, 200
    else
        findFolder req.params.id, (err, folder) ->
            if err
                res.send error: true, msg: err, 404
            else
                Folder.byFolder key: folder.path + '/' + folder.name ,(err, folders) ->
                    if err
                        res.send error: true, msg: "Server error occured", 500
                    else
                        res.send folders, 200


module.exports.destroy = (req, res) ->
    findFolder req.params.id, (err, currentFolder) ->
        if err
            res.send error: true, msg: err, 404
        else
            # Remove folders in the current folder
            Folder.all (err, folders) =>
                if err
                    res.send error: true, msg:  "Server error occured", 500
                else
                    for folder in folders
                        directory = currentFolder.path + '/' + currentFolder.name
                        if (folder.path.indexOf(directory) is 0)
                            folder.destroy (err) ->
                                console.log err if err
                    # Remove files in the current folder
                    File.all (err, files) =>
                        if err
                            res.send error: true, msg:  "Server error occured", 500
                        else
                            for file in files
                                directory = currentFolder.path + '/' + currentFolder.name
                                if (file.path.indexOf(directory) is 0)
                                    file.removeBinary "file", (err) ->
                                        file.destroy (err) ->
                                            console.log err if err
                             # Remove the current folder
                            currentFolder.destroy (err) ->
                                if err
                                    compound.logger.write err
                                    res.send error: 'Cannot destroy folder', 500
                                else
                                    res.send success: 'Folder succesfuly deleted', 200