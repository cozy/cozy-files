americano = require 'americano'

staticMiddleware = americano.static __dirname + '/../client/public',
            maxAge: 86400000

publicStatic = (req, res, next) ->
    url = req.url
    req.url = req.url.replace '/public/assets', ''
    staticMiddleware req, res, (err) ->
        req.url = url
        next err

config =
    common:
        set:
            'view engine': 'jade'
            'views': './server/views'
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
