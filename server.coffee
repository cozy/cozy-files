americano = require 'americano'
initFilter = require './server/initializers/filter'

port = process.env.PORT || 9250
americano.start name: 'cozy-files', port: port, (app, server) ->
	app.server = server
	initFilter()