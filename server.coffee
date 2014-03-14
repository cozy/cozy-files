americano = require 'americano'
errorHandler = require './server/middlewares/errors'

options =
    name: 'cozy-files'
    root: __dirname
    port: process.env.PORT || 9121
    host: process.env.HOST || '127.0.0.1'

americano.start options, (app, server) ->
    app.server = server
    app.use errorHandler

    RealtimeAdapter = require 'cozy-realtime-adapter'

    # notification events should be proxied to client
    realtime = RealtimeAdapter server: server, ['file.*', 'folder.*', 'contact.*']
