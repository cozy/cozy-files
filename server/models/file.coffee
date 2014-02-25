americano = require 'americano-cozy'

module.exports = File = americano.getModel 'File',
    path: String
    name: String
    permissions: String
    creationDate: String
    lastModification: String
    class: String
    size: Number
    binary: Object
    modificationHistory: Object
    public: Boolean


File.all = (params, callback) ->
    File.request "all", params, callback

File.byFolder = (params, callback) ->
    File.request "byFolder", params, callback
