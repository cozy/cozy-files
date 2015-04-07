path = require 'path'
americano = require 'americano'
errorHandler = require './middlewares/errors'
getTemplateExt = require './helpers/get_template_ext'

staticMiddleware = americano.static path.resolve(__dirname, '../client/public'),
            maxAge: 86400000

publicStatic = (req, res, next) ->

    # Allows assets to be loaded from any route
    detectAssets = /\/(stylesheets|javascripts|images|fonts)+\/(.+)$/
    assetsMatched = detectAssets.exec req.url

    if assetsMatched?
        req.url = assetsMatched[0]

    staticMiddleware req, res, (err) -> next err

GB = 1024 * 1024 * 1024

config =
    common:
        set:
            'view engine': getTemplateExt()
            'views': path.resolve __dirname, 'views'

        engine:
            js: (path, locales, callback) ->
                callback null, require(path)(locales)

        use: [
            americano.bodyParser()
            staticMiddleware
            publicStatic
        ]
        afterStart: (app, server) ->
            # move here necessary after express 4.4
            app.use errorHandler

    development: [
        americano.logger 'dev'
    ]
    production: [
        americano.logger 'short'
    ]
    plugins: [
        'cozydb'
    ]

module.exports = config
