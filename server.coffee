americano = require 'americano'
errorHandler = require './server/middlewares/errors'

port = process.env.PORT || 9250
americano.start name: 'cozy-files', port: port, (app, server) ->
    app.server = server
    app.use errorHandler

    RealtimeAdapter = require 'cozy-realtime-adapter'

    customCb = (event, msg) ->
        console.log "Socket.io event received: #{event} #{msg}"

    # notification events should be proxied to client
    realtime = RealtimeAdapter server: server, ['file.*', 'folder.*']
    realtime.on 'file.*', customCb
    realtime.on 'folder.*', customCb
