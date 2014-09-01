Realtimer = require 'cozy-realtime-adapter'

module.exports = (server, callback) ->
    # make client realtime
    realtime = Realtimer server: server, ['contact.*']
    callback()
