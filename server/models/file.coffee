americano = require 'americano-cozy'

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


File.all = (params, callback) ->
    File.request "all", params, callback

File.byFolder = (params, callback) ->
    File.request "byFolder", params, callback

File::getFullPath = ->
    @path + '/' + @name

File::getPublicURL = (cb) ->
    CozyInstance.getURL (err, domain) =>
        return cb err if err
        url = "#{domain}public/files/files/#{@id}"
        cb null, url