Folder = require '../models/folder'
File = require '../models/file'
CozyInstance = require '../models/cozy_instance'
jade = require 'jade'
async = require 'async'
sharing = require '../helpers/sharing'
archiver = require 'archiver'

publicfoldertemplate = require('path').join __dirname, '../views/publicfolder.jade'

KB = 1024
MB = KB * KB

## Helpers ##

findFolder = (id, callback) ->
    Folder.find id, (err, folder) =>
        if err or not folder
            callback "Folder not found"
        else
            callback null, folder

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

module.exports.tree = (req, res) ->
    findFolder req.params.id, (err, folderChild) ->
        if err
            res.send error: true, msg:  "Server error occured: #{err}", 500
        else
            Folder.all (err, folders) =>

                isParent = (folder, cb) ->
                    if (folderChild.path+"/").indexOf(folder.path + "/" + folder.name + "/") is 0
                        cb null, [folder]
                    else
                        cb null, []

                # check that the name is not already taken
                async.concat folders, isParent, (err, parents) ->
                    if err
                        res.send error: true, msg: "Couldn't find the tree: : #{err}", 500
                    else
                        parents = parents.sort (a, b) ->
                            if a.path + "/" + a.name < b.path + "/" + b.name then return -1
                            else return 1

                        res.send parents, 200


module.exports.modify = (req, res) ->
    if not req.body.name? and not req.body.public?
        return res.send error: true, msg: "Data required", 400

    findFolder req.params.id, (err, folderToModify) ->
        return next err if err

        newName = req.body.name
        isPublic = req.body.public
        oldPath = folderToModify.path + '/' + folderToModify.name + "/"
        newPath = folderToModify.path + '/' + newName + "/"

        hasntTheSamePathOrIsTheSame = (folder, cb) ->
            if (folderToModify.id is folder.id)
                cb true
            else
                cb (newPath isnt (folder.path + '/' + folder.name + "/"))

        updateIfIsSubFolder = (file, cb) ->
            if ((file.path + "/").indexOf(oldPath) is 0)

                oldRealPath = folderToModify.path + '/' + folderToModify.name
                newRealPath = folderToModify.path + '/' + newName
                modifiedPath = file.path.replace oldRealPath, newRealPath

                file.updateAttributes path: modifiedPath, cb
            else
                cb null

        updateTheFolder = ->
            # update the folder itself
            data =
                name: newName
                public: isPublic

            data.clearance = req.body.clearance if req.body.clearance

            folderToModify.updateAttributes data, (err) =>
                return next err if err

                # update index too
                folderToModify.index ["name"], (err) ->
                    if err
                        res.send error: true, msg: "Couldn't index: #{err}", 500
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
                            res.send error: true, msg: "Server error occured while deleting subdirectories: #{err}", 500
                        else

                            File.all (err, files) =>
                                if err
                                    res.send error: true, msg:  "Server error occured: #{err}", 500
                                else
                                    # Remove files in this directory
                                    async.each files, destroyIfIsSubdirectory, (err) ->
                                        if err
                                            res.send error: true, msg: "Server error occured when deleting sub files: #{err}", 500
                                        else
                                             # Remove the current folder
                                            currentFolder.destroy (err) ->
                                                if err
                                                    res.send error: "Cannot destroy folder: #{err}", 500
                                                else
                                                    res.send success: "Folder succesfuly deleted: #{err}", 200

module.exports.findFiles = (req, res) ->
    getFolderPath req.body.id, (err, key) ->
        if err
            res.send error: true, msg: "Server error occured: #{err}", 500
        else
            File.byFolder key: key ,(err, files) ->
                if err
                    res.send error: true, msg: "Server error occured: #{err}", 500
                else
                    res.send files, 200

module.exports.findFolders = (req, res) ->
    getFolderPath req.body.id, (err, key) ->
        if err
            res.send error: true, msg: "Server error occured: #{err}", 500
        else
            Folder.byFolder key: key ,(err, files) ->
                if err
                    res.send error: true, msg: "Server error occured: #{err}", 500
                else
                    res.send files, 200

module.exports.search = (req, res) ->
    Folder.search "*#{req.body.id}*", (err, files) ->
        if err
            res.send error: true, msg: "Server error occured: #{err}", 500
        else
            res.send files

module.exports.zip = (req, res) ->
    getFolderPath req.params.id, (err, key) ->
        if err
            res.send error: true, msg: "Server error occured: #{err}", 500
        else
            File.all (err, files) ->
                if err
                    res.send error: true, msg: "Server error occured: #{err}", 500
                else
                    # find the name
                    findFolder req.params.id, (err, folder) ->
                        if err or not folder
                            res.send 404
                        else
                            zipName = folder.name?.replace(/\W/g, '')

                            isContained = (file, cb) ->
                                if (file.path+"/").indexOf(key+"/") is 0
                                    cb null, [file]
                                else
                                    cb null, []

                            # check that the name is not already taken
                            async.concat files, isContained, (err, files) ->
                                if err
                                    res.send error:true, msg: "Server error", 400
                                else
                                    archive = archiver('zip')

                                    addToArchive = (file, cb) ->
                                        stream = file.getBinary "file", (err, resp, body) =>
                                            if err
                                                res.send error: true, msg: "Server error occured: #{err}", 500
                                        name = file.path.replace(key, "") + "/" + file.name
                                        archive.append stream, name: name, cb

                                    async.eachSeries files, addToArchive, (err) ->
                                        if err
                                            res.send error: true, msg: "Server error occured: #{err}", 500
                                        else
                                            archive.pipe res

                                            disposition = "attachment; filename=\"#{zipName}.zip\""
                                            res.setHeader 'Content-Disposition', disposition
                                            res.setHeader 'Content-Type', 'application/zip'

                                    archive.finalize (err, bytes) ->
                                        if err
                                            res.send error: true, msg: "Server error occured: #{err}", 500
                                        else
                                            console.log "Zip created"


module.exports.publicList = (req, res) ->

    errortemplate = (err) ->
        console.log err
        res.send err.stack or err

    findFolder req.params.id, (err, folder) ->
        return errortemplate err if err

        sharing.limitedTree folder, req, (path) ->
            authorized = path.length isnt 0
            return res.send 404 unless authorized

            key = folder.path + '/' + folder.name
            async.parallel [
                (cb) -> CozyInstance.getLocale cb
                (cb) -> Folder.byFolder key:key, cb
                (cb) -> File.byFolder key:key, cb
            ], (err, results) ->
                return errortemplate err if err
                [lang, folders, files] = results

                translations = try require '../../client/app/locales/' + lang
                catch e
                    try require '../../../client/app/locales/' + lang
                    catch e then {}
                translate = (text) -> translations[text] or text

                #format date & size
                files = files.map (file) ->

                    file = file.toJSON()

                    file.lastModification = new Date(file.lastModification)
                    .toISOString().split('T').join(' ').split('.')[0]

                    file.size = if file.size > MB
                        (parseInt(file.size) / MB).toFixed(1) + translate "MB"
                    else if file.size > KB
                        (parseInt(file.size) / KB).toFixed(1) + translate "KB"
                    else
                        file.size + translate "B"

                    return file

                locals = {
                    path
                    files
                    folders
                    keyquery: "?key=#{req.query.key}"
                    t: translate
                }

                try
                    html = jade.renderFile publicfoldertemplate, locals
                    res.send html
                catch err
                    errortemplate err


module.exports.publicZip = (req, res) ->

    errortemplate = (err) ->
        res.send err.stack or err

    findFolder req.params.id, (err, folder) ->
        return errortemplate err if err

        sharing.checkClearance folder, req, (authorized) ->
            if not authorized then res.send 404
            else module.exports.zip req, res