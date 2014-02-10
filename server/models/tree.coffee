americano = require 'americano-cozy'
module.exports = Tree = americano.getModel 'Tree',
    type: String
    struct: Object

Tree.all = (params, callback) ->
    Tree.request 'byType', params, callback
