patch1 = require './server/initializers/patch1'
logwatch = require './server/initializers/finglogwatch'


start = (port, callback) ->
    require('americano').start
            name: 'Contacts'
            port: port
    , (app, server) ->
        app.set 'views', './client/'

        # run patch to fix old contacts
        patch1 (err) ->
            return callback? err if err

            # start realtime and sync Fing's log with contact's log
            logwatch server, (err) ->

                callback? err, app, server

if not module.parent
    port = process.env.PORT or 9114
    start port, (err) ->
        if err
            console.log "Initialization failed, not starting"
            console.log err.stack
            process.exit 1

else
    module.exports = start
