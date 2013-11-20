Folder = require '../models/folder'
File = require '../models/file'
async = require 'async'

## Helpers ##

findFolder = (id, callback) ->
    Folder.find id, (err, file) =>
        if err or not file
            callback "File not found"
        else
            callback null, file 

getFolderPath = (id, cb) ->
    if id is 'root'
        cb null, ""
    else
        findFolder id, (err, folder) ->
            if err
                cb err
            else
                cb null, folder.path + '/' + folder.name

## Actions ##

module.exports.create = (req, res) ->
    if (not req.body.name) or (req.body.name == "")
        res.send error:true, msg: "Invalid arguments", 500
    else
        Folder.all (err, folders) =>

            hasntTheSamePath = (folder, cb) ->
                cb ((req.body.path + '/' + req.body.name) isnt (folder.path + '/' + folder.name))

            # check that the name is not already taken
            async.every folders, hasntTheSamePath, (available) ->
                if not available
                    res.send error:true, msg: "This folder already exists", 400
                else                    
                    Folder.create req.body, (err, newFolder) ->
                        if err
                            console.log err
                            res.send error: true, msg: "Server error while creating file: #{err}", 500
                        else
                            newFolder.index ["name"], (err) ->
                                if err
                                    console.log err
                                    res.send error: true, msg: "Couldn't index: : #{err}", 500
                                else
                                    res.send newFolder, 200

module.exports.find = (req, res) ->
    findFolder req.params.id, (err, folder) ->
        if err
            res.send error: true, msg: err, 404
        else   
            res.send folder, 200

module.exports.modify = (req, res) ->
    if (not req.body.name) or (req.body.name == "")
        res.send error: true, msg: "No filename specified", 500
    else

        findFolder req.params.id, (err, folderToModify) ->
            if err
                res.send error: true, msg:  "Server error occured: #{err}", 500
            else
                newName = req.body.name
                oldPath = folderToModify.path + '/' + folderToModify.name
                newPath = folderToModify.path + '/' + newName

                hasntTheSamePathOrIsTheSame = (folder, cb) ->
                    if (folderToModify.id is folder.id)
                        cb true
                    else
                        cb (newPath isnt (folder.path + '/' + folder.name))

                updateIfIsSubFolder = (file, cb) ->
                    if (file.path.indexOf(oldPath) is 0)
                        console.log "Moving '#{file.name}': '#{oldPath}/#{file.name}'' -> '#{newPath}/#{file.name}'"
                        modifiedPath = file.path.replace oldPath, newPath
                        file.updateAttributes path: modifiedPath, cb
                    else
                        cb null

                updateTheFolder = ->
                    # update the folder itself
                    folderToModify.updateAttributes name: newName, (err) =>
                        if err
                            res.send error: 'Cannot modify file: #{err}', 500
                        else
                            # index the new data
                            folderToModify.index ["name"], (err) ->
                                if err
                                    console.log err
                                    res.send error: true, msg: "Couldn't index: : #{err}", 500
                                else
                                    res.send success: 'File succesfuly modified', 200

                updateFoldersAndFiles = (folders)->
                    # update all folders
                    async.each folders, updateIfIsSubFolder, (err) ->
                        if err
                            res.send error: true, msg: "Error updating folders: #{err}", 500
                        else
                            # update all files
                            File.all (err, files) =>
                                if err
                                    res.send error: true, msg: "Server error occured: #{err}", 500
                                else
                                    async.each files, updateIfIsSubFolder, (err) ->
                                        if err
                                            res.send error: true, msg: "Error updating files: #{err}", 500
                                        else
                                            updateTheFolder()
                
                
                Folder.all (err, folders) =>
                    if err
                        res.send error: true, msg:  "Server error occured: #{err}", 500
                    else
                        # check that the new name isn't taken
                        async.every folders, hasntTheSamePathOrIsTheSame, (available) ->
                            if not available
                                res.send error: true, msg: "The name already in use", 400
                            else
                                updateFoldersAndFiles folders


module.exports.destroy = (req, res) ->
    findFolder req.params.id, (err, currentFolder) ->
        if err
            res.send error: true, msg: err, 404
        else
            directory = currentFolder.path + '/' + currentFolder.name

            destroyIfIsSubdirectory = (file, cb) ->
                if (file.path.indexOf(directory) is 0)
                    console.log "Deleting '#{file.name}'"
                    if file.binary
                        file.removeBinary "file", (err) ->
                            if err
                                cb err
                            else
                                file.destroy cb
                    else
                        file.destroy cb
                else
                    cb null
            
            Folder.all (err, folders) =>
                if err
                    res.send error: true, msg: "Server error occured: #{err}", 500
                else
                    # Remove folders in the current folder
                    async.each folders, destroyIfIsSubdirectory, (err) ->
                        if err
                            console.log err
                            res.send error: true, msg: "Server error occured while deleting subdirectories: #{err}", 500
                        else
                            
                            File.all (err, files) =>
                                if err
                                    res.send error: true, msg:  "Server error occured: #{err}", 500
                                else
                                    # Remove files in this directory
                                    async.each files, destroyIfIsSubdirectory, (err) ->
                                        if err
                                            console.log err
                                            res.send error: true, msg: "Server error occured when deleting sub files: #{err}", 500
                                        else
                                             # Remove the current folder
                                            currentFolder.destroy (err) ->
                                                if err
                                                    console.log err
                                                    res.send error: "Cannot destroy folder: #{err}", 500
                                                else
                                                    res.send success: "Folder succesfuly deleted: #{err}", 200

module.exports.findFiles = (req, res) ->
    getFolderPath req.params.id, (err, key) ->
        if err
            res.send error: true, msg: "Server error occured: #{err}", 500
        else
            File.byFolder key: key ,(err, files) ->
                if err
                    res.send error: true, msg: "Server error occured: #{err}", 500
                else
                    res.send files, 200 

module.exports.findFolders = (req, res) ->
    getFolderPath req.params.id, (err, key) ->
        if err
            res.send error: true, msg: "Server error occured: #{err}", 500
        else
            Folder.byFolder key: key ,(err, files) ->
                if err
                    res.send error: true, msg: "Server error occured: #{err}", 500
                else
                    res.send files, 200 
