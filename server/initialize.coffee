localization = require './lib/localization_manager'
RealtimeAdapter = require 'cozy-realtime-adapter'

module.exports.beforeStart = (callback) ->
    localization.initialize callback
module.exports.afterStart = (app, server, callback) ->

    # retrieve locale and set polyglot object
        # notification events should be proxied to client
        realtime = RealtimeAdapter server: server, ['file.*', 'folder.*', 'contact.*']

        callback() if callback?