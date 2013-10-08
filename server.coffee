americano = require 'americano'

port = process.env.PORT || 9250
americano.start name: 'cozy-files', port: port, (app, server) ->
	app.server = server
