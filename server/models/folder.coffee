americano = require 'americano-cozy'

module.exports = Folder = americano.getModel 'Folder',
    path: String
    name: String
    slug: String

Folder.all = (params, callback) ->
    Folder.request "all", params, callback
Folder.byFolder = (params, callback) ->
    Folder.request "byFolder", params, callback