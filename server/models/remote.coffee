americano = require 'americano-cozy'

module.exports = Remote = americano.getModel 'Remote',
    login: String
    password: String

Remote.all = (params, callback) ->
    Remote.request "all", params, callback