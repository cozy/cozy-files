americano = require 'americano'

staticMiddleware = americano.static __dirname + '/../client/public',
            maxAge: 86400000

config =
    common:
        set:
            'view engine': 'jade'
            'views': './server/views'
        use: [
            staticMiddleware
            # below middleware = app.use '/public/assets', staticMiddleware
            (req, res, next) ->
                url = req.url
                req.url = req.url.replace '/public/assets', ''
                staticMiddleware req, res, (err) ->
                    req.url = url
                    next err

            americano.bodyParser()
            require('cozy-i18n-helper').middleware
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
