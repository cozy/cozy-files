File = require '../models/file'
Folder = require '../models/folder'


# Update index
# Usefull for file/folder added by a device when app was stopped
module.exports.updateIndex = (callback) ->
    File.all (err, files) ->
        if err
            next err
        else
            for file in files
                file.index ['name'], () =>
    Folder.all (err, folders) ->
        if err
            next err
        else
            for folder in folders
                folder.index ['name'], () =>