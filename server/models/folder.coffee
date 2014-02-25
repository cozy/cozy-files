americano = require 'americano-cozy'

module.exports = Folder = americano.getModel 'Folder',
    path: String
    name: String
    permissions: String
	creationDate: String
	lastModification: String
	size: Number
	modificationHistory: Object
    public: Boolean

Folder.all = (params, callback) ->
    Folder.request "all", params, callback

Folder.byFolder = (params, callback) ->
    Folder.request "byFolder", params, callback
