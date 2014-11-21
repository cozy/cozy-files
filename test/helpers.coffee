path = require 'path'
Client = require('request-json').JsonClient

helpers = {}
if process.env.USE_JS
    helpers.prefix = path.join __dirname, '../build/'
else
    helpers.prefix = path.join __dirname, '../'

# server management
helpers.options =
    serverHost: process.env.HOST or 'localhost'
    serverPort: process.env.PORT or 9121

# default client
client = new Client "http://#{helpers.options.serverHost}:#{helpers.options.serverPort}/", jar: true

# set the configuration for the server
process.env.HOST = helpers.options.serverHost
process.env.PORT = helpers.options.serverPort

# Returns a client if url is given, default app client otherwise
helpers.getClient = (url = null) ->
    if url?
        return new Client url, jar: true
    else
        return client

initializeApplication = require "#{helpers.prefix}server"
CozyInstance = require "#{helpers.prefix}/server/models/cozy_instance"

helpers.ensureCozyInstance = (done) ->
    all = (doc) -> emit doc._id, doc; return
    CozyInstance.defineRequest 'all', all, (err) ->
        return done err if err
        CozyInstance.first (err, instance) ->
            return done null if instance
            CozyInstance.create
                domain: 'domain.not.set',
                locale: 'en'
            , done

helpers.startApp = (done) ->
    @timeout 15000
    initializeApplication (app, server) =>
        @app = app
        @app.server = server
        done()

helpers.stopApp = (done) ->
    @timeout 10000
    setTimeout =>
        @app.server.close done
    , 1000

# Bring models in context
File = require "#{helpers.prefix}server/models/file"
Folder = require "#{helpers.prefix}server/models/folder"

# This function remove everythin from the db
helpers.cleanDB = (callback) ->
    @timeout 15000
    Folder.destroyAll (err) ->
        if err then callback err
        else File.destroyAll callback

module.exports = helpers
