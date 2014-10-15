contactwatch = require './server/initializers/contactwatch'
americano = require('americano')


start = (port, callback) ->
    americano.start
        name: 'Contacts'
        port: port
        root: __dirname
    , (app, server) ->

        # start contact watch to upadte UI when new contact are added
        # or modified
        contactwatch server, (err) ->
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
