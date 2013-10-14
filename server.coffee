start = (port, callback) ->
    require('americano').start
            name: 'Contacts'
            port: port
    , (app, server) ->
        app.set 'views', './client/'
        patch1 = require './server/patches/patch1'
        patch1 (err) -> callback? err, app, server

if not module.parent
    port = process.env.PORT or 9114
    start port, (err) ->
        if err
            console.log "Initialization failed, not starting"
            console.log err.stack
            process.exit 1

else
    module.exports = start
