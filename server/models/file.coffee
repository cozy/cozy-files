americano = require 'americano-cozy'

module.exports = File = americano.getModel 'File',
    path: String
    name: String
    slug: String
    binary: String
    _attachment: Object

File.all = (params, callback) ->
    File.request "all", params, callback
File.byFolder = (params, callback) ->
    File.request "byFolder", params, callback