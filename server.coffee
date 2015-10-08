americano = require 'americano'
errorHandler = require './server/middlewares/errors'
initialize = require './server/initialize'

application = module.exports = (callback) ->
    options =
        name: 'cozy-files'
        root: __dirname
        port: process.env.PORT || 9121
        host: process.env.HOST || '127.0.0.1'

    initialize.beforeStart ->
        americano.start options, (err, app, server) ->
            app.server = server
            app.use errorHandler
            initialize.afterStart app, server, callback

if not module.parent
    application()
