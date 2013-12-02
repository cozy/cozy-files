americano = require 'americano'

port = process.env.PORT || 9250
americano.start name: 'cozy-files', port: port, (app, server) ->
    app.server = server

    RealtimeAdapter = require 'cozy-realtime-adapter'

    customCb = (event, msg) ->
        console.log "Socket.io event received: #{event} #{msg}"

    # notification events should be proxied to client
    realtime = RealtimeAdapter server: server, ['notification.*']
    realtime.on 'file.*', customCb
    realtime.on 'folder.*', customCb
