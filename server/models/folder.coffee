americano = require 'americano-cozy'
moment = require 'moment'
CozyInstance = require './cozy_instance'

module.exports = Folder = americano.getModel 'Folder',
    path: String
    name: String
    docType: String
    creationDate: String
    lastModification: String
    size: Number
    modificationHistory: Object
    changeNotification: Boolean
    clearance: (x) -> x
    tags: (x) -> x

Folder.all = (params, callback) ->
    Folder.request "all", params, callback

Folder.byFolder = (params, callback) ->
    Folder.request "byFolder", params, callback

Folder.byFullPath = (params, callback) ->
    Folder.request "byFullPath", params, callback

# New folder Creation process:
# * Create new folder.
# * Index the folder name.
Folder.createNewFolder = (folder, callback) ->
    Folder.create folder, (err, newFolder) ->
        if err then callback err
        else
            newFolder.index ["name"], (err) ->
                console.log err if err
                callback null, newFolder

Folder.allPath = (callback) ->
    Folder.request "byFullPath", (err, folders) ->
        return callback err if err
        paths = []
        paths.push folder.getFullPath() for folder in folders
        callback null, paths

Folder::getFullPath = ->
    @path + '/' + @name

Folder::getParents = (callback) ->
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

Folder::getPublicURL = (cb) ->
    CozyInstance.getURL (err, domain) =>
        return cb err if err
        url = "#{domain}public/files/folders/#{@id}"
        cb null, url

Folder::updateParentModifDate = (callback) ->
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
    Folder::index = (fields, callback) -> callback null
    Folder::search = (query, callback) -> callback null, []

