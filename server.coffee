logwatch = require './server/initializers/finglogwatch'
americano = require('americano')


start = (port, callback) ->
    americano.start
        name: 'Contacts'
        port: port
    , (app, server) ->

        # start realtime and sync Fing's log with contact's log
        logwatch server, (err) ->
            callback? null, app, server

if not module.parent
    port = process.env.PORT or 9114
    start port, (err) ->
        if err
            console.log "Initialization failed, not starting"
            console.log err.stack
            process.exit 1

else
    module.exports = start
