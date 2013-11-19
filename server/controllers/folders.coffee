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

module.exports.modify = (req, res) ->
    if not req.body.name or req.body.name == ""
        res.send error: true, msg: "No filename specified", 404
    else
        newName = req.body.name

        findFolder req.params.id, (err, folderUpdated) ->
            # test if the folder name is available
            conflict = false
            Folder.all (err, folders) =>

                conflict = false
                for folder in folders
                    # it's not the same folder
                    if not (folderUpdated.id is folder.id)
                        # but has the same path and the desired name
                        if (folderUpdated.path is folder.path) and (newName is folder.name)
                            conflict = true
                            res.send error:true, msg: "This foldername is already in use", 400

                if not conflict

                    # update all files and folders this folder contains
                    File.all (err, files) =>
                        if err
                            res.send error: true, msg:  "Server error occured", 500
                        else
                            for file in files

                                oldPath = folderUpdated.path + '/' + folderUpdated.name
                                # check if their path contains the folder being updated
                                if (file.path.indexOf(oldPath) is 0)

                                    newPath = folderUpdated.path + '/' + newName
                                    modifiedPath = file.path.replace oldPath, newPath

                                    console.log "Updating sub file: #{oldPath} -> #{newPath}"

                                    file.updateAttributes path: modifiedPath, (err) =>
                                        if err
                                            compound.logger.write err
                                            console.log err

                            Folder.all (err, folders) =>
                                if err
                                    res.send error: true, msg:  "Server error occured", 500
                                else
                                    for folder in folders

                                        oldPath = folderUpdated.path + '/' + folderUpdated.name
                                        # check if their path contains the folder being updated
                                        if (folder.path.indexOf(oldPath) is 0)

                                            newPath = folderUpdated.path + '/' + newName
                                            modifiedPath = folder.path.replace oldPath, newPath

                                            console.log "Updating sub folder: #{oldPath} -> #{newPath}"

                                            folder.updateAttributes path: modifiedPath, (err) =>
                                                if err
                                                    compound.logger.write err
                                                    console.log err

                                    # update the folder itself
                                    folderUpdated.updateAttributes name: newName, (err) =>
                                        if err
                                            compound.logger.write err
                                            res.send error: 'Cannot modify file', 500
                                        else
                                            res.send success: 'File succesfuly modified', 200


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
                Folder.byFolder key: folder.path + '/' + folder.name, (err, folders) ->
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
                                        console.log err if err
                                        file.destroy (err) ->
                                            console.log err if err
                             # Remove the current folder
                            currentFolder.destroy (err) ->
                                if err
                                    compound.logger.write err
                                    res.send error: 'Cannot destroy folder', 500
                                else
                                    res.send success: 'Folder succesfuly deleted', 200