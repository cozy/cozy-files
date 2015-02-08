File = require '../models/file'
Folder = require '../models/folder'
async = require 'async'


# Update index
# Usefull for file/folder added by a device when app was stopped
module.exports.updateIndex = (callback) ->
    File.all (err, files) ->
        if err
            console.log err
        else
            async.eachSeries files, (file) ->
                file.index ['name'], ->
            , ->
                Folder.all (err, folders) ->
                    if err
                        console.log err
                    else
                        async.eachSeries folders, (folder) ->
                            folder.index ['name'], ->
                        , ->
                            console.log 'Re-indexation is done.'
                            callback() if callback
