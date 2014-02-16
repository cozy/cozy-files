americano = require 'americano'
errorHandler = require './server/middlewares/errors'

options =
    name: 'cozy-files'
    port: process.env.PORT || 9121
    host: process.env.HOST || '127.0.0.1'

americano.start options, (app, server) ->
    app.server = server
    app.use errorHandler

    RealtimeAdapter = require 'cozy-realtime-adapter'

    customCb = (event, msg) ->
        console.log "Socket.io event received: #{event} #{msg}"

    # notification events should be proxied to client
    realtime = RealtimeAdapter server: server, ['file.*', 'folder.*']
    realtime.on 'file.*', customCb
    realtime.on 'folder.*', customCb
