express = require 'express'
init = require './init'
router = require './server/router'
configure = require './server/config'

module.exports = app = express()
configure(app)
router(app)

if not module.parent
    init -> # ./init.coffee
        port = process.env.PORT or 9114
        host = process.env.HOST or "127.0.0.1"

        app.listen port, host, ->
            console.log "Server listening on %s:%d within %s environment",
                host, port, app.get('env')