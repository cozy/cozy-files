contactwatch = require './server/initializers/contactwatch'
americano = require('americano')


start = (host, port, callback) ->
    americano.start
        name: 'Contacts'
        port: port
        root: __dirname
        host: host
    , (app, server) ->

        # start contact watch to upadte UI when new contact are added
        # or modified
        contactwatch server, (err) ->
            callback? null, app, server

if not module.parent
    host = process.env.HOST or '127.0.0.1'
    port = process.env.PORT or 9114
    start host, port, (err) ->
        if err
            console.log "Initialization failed, not starting"
            console.log err.stack
            process.exit 1

else
    module.exports = start
