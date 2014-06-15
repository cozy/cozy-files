fs = require 'fs'
americano = require 'americano-cozy'
moment = require 'moment'

Folder = require './folder'
CozyInstance = require './cozy_instance'

module.exports = File = americano.getModel 'File',
    path: String
    name: String
    docType: String
    creationDate: String
    lastModification: String
    class: String
    size: Number
    binary: Object
    modificationHistory: Object
    clearance: (x) -> x
    tags: (x) -> x


File.all = (params, callback) ->
    File.request "all", params, callback

File.byFolder = (params, callback) ->
    File.request "byFolder", params, callback

File.byFullPath = (params, callback) ->
    File.request "byFullPath", params, callback


# Perform all operation required to create a new file:
# * Create document.
# * Create a binary Document and attach file to it.
# * Index file name for better search
# * Remove temporary created file.
File.createNewFile = (data, file, callback) =>
    attachBinary = (newFile) ->
        newFile.attachBinary file.path, {"name": "file"}, (err) ->
            if err
                newFile.destroy (err) ->
                    callback new Error "Error attaching binary: #{err}"
            else
                index newFile

    index = (newFile) ->
        newFile.index ["name"], (err) ->
            console.log err if err
            unlink newFile

    unlink = (newFile) ->
       fs.unlink file.path, (err) ->
            if err
                callback new Error "Error removing uploaded file: #{err}"
            else
                callback null, newFile

    File.create data, (err, newFile) =>
        if err
            callback new Error "Server error while creating file; #{err}"
        else
            attachBinary newFile

File::getFullPath = ->
    @path + '/' + @name

File::getPublicURL = (cb) ->
    CozyInstance.getURL (err, domain) =>
        return cb err if err
        url = "#{domain}public/files/files/#{@id}"
        cb null, url

File::getParents = (callback) ->
    Folder.all (err, folders) =>
        return callback err if err

        # only look at parents
        fullPath = @getFullPath()
        parents = folders.filter (tested) ->
            fullPath.indexOf(tested.getFullPath()) is 0

        # sort them in path order
        parents.sort (a,b) ->
            a.getFullPath().length - b.getFullPath().length

        callback null, parents

File::updateParentModifDate = (callback) ->
    Folder.byFullPath key: @path, (err, parents) =>
        if err
            callback err
        else if parents.length > 0
            parent = parents[0]
            parent.lastModification = moment().toISOString()
            parent.save callback
        else
            callback()



if process.env.NODE_ENV is 'test'
    File::index = (fields, callback) -> callback null
    File::search =  (query, callback) -> callback null, []

