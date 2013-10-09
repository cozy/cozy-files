http = require('http')
Client = require('request-json').JsonClient
americano = require 'americano'

clientDS = new Client 'http://localhost:9101'

# Bring models in context
File = require '../server/models/file'
Folder = require '../server/models/folder'
Remote = require '../server/models/remote'

process.env.NAME = "files"
process.env.TOKEN = "token"

helpers = {}

# init the compound application
# will create @app in context
# usage : before helpers.init port
_init = (ctx, port, done) ->
    params = name: 'Cozy Files', port: port
    americano.start params, (app, server) =>
        app.server = server
        ctx.app = app
        done()

# This function remove everythin from the db
helpers.cleanDb = (callback) ->
    Folder.destroyAll (err) ->
        return callback err if err
        File.destroyAll (err) ->
            return callback err if err
            Remote.destroyAll (err) ->
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
helpers.createApp = (name, slug, password, index, state) -> (callback) ->
	data =
        name: name
        state: state
        index: index
        slug: slug
        password: password
        docType: "Application"
    clientDS.setBasicAuth 'home', 'token'
    clientDS.post 'data/', data, callback

module.exports = helpers