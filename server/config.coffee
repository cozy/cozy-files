path = require 'path'
americano = require 'americano'

staticMiddleware = americano.static path.resolve(__dirname, '../client/public'),
            maxAge: 86400000

publicStatic = (req, res, next) ->

    # Allows assets to be loaded from any route
    detectAssets = /\/(stylesheets|javascripts)+\/(.+)$/
    assetsMatched = detectAssets.exec req.url

    if assetsMatched?
        req.url = assetsMatched[0]

    staticMiddleware req, res, (err) -> next err

GB = 1024 * 1024 * 1024

config =
    common:
        set:
            'view engine': 'jade'
            'views': path.resolve __dirname, 'views'
        use: [
            americano.bodyParser()
            require('cozy-i18n-helper').middleware
            americano.errorHandler
                dumpExceptions: true
                showStack: true

            staticMiddleware
            publicStatic

        ]
    development: [
        americano.logger 'dev'
    ]
    production: [
        americano.logger 'short'
    ]
    plugins: [
        'americano-cozy'
    ]

module.exports = config
