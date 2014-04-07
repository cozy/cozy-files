americano = require 'americano-cozy'
CozyInstance = require './cozy_instance'

module.exports = Folder = americano.getModel 'Folder',
    path: String
    name: String
    docType: String
    creationDate: String
    lastModification: String
    size: Number
    modificationHistory: Object
    clearance: (x) -> x
    tags: (x) -> x

Folder.all = (params, callback) ->
    Folder.request "all", params, callback

Folder.byFolder = (params, callback) ->
    Folder.request "byFolder", params, callback

Folder::getFullPath = ->
    @path + '/' + @name

Folder::getPublicURL = (cb) ->
    CozyInstance.getURL (err, domain) =>
        return cb err if err
        url = "#{domain}public/files/folders/#{@id}"
        cb null, url

if process.env.NODE_ENV is 'test'
    Folder::index = (fields, callback) -> callback null
    Folder::search = (query, callback) -> callback null, []
