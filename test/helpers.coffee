http = require('http')
Client = require('request-json').JsonClient
americano = require 'americano'

clientDS = new Client 'http://localhost:9101'


helpers = {}
ref = if process.env.COVERAGE
    helpers.prefix = '../instrumented/'
else if process.env.USE_JS
    helpers.prefix = '../build/'
else
    helpers.prefix = '../'

# Bring models in context
File = require helpers.prefix + 'server/models/file'
Folder = require helpers.prefix + 'server/models/folder'


# init the compound application
# will create @app in context
# usage : before helpers.init port
_init = (ctx, port, done) ->
    params = name: 'files', port: port
    americano.start params, (app, server) =>
        app.server = server
        ctx.app = app
        done()

# This function remove everythin from the db
helpers.cleanDb = (callback) ->
    Folder.destroyAll (err) ->
        console.log err
        return callback err if err
        File.destroyAll (err) ->
            return callback err

helpers.setup = (port) ->
    (done) ->
        @timeout 5000
        _init this, port, (err) =>
            return done err if err
            _clearDb done

helpers.takeDown = (done) ->
    @app.server.close()
    _clearDb done


# function factory for creating application
helpers.createApp = (name, slug, password, index, state) -> 
	data =
        name: name
        state: state
        index: index
        slug: slug
        password: password
        permissions: 
            "All": 
                description: "test"
        docType: "Application"
    clientDS.setBasicAuth 'home', 'token'
    clientDS.post 'data/', data, (err, res, body)=>
        console.log err if err?

module.exports = helpers