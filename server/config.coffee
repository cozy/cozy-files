module.exports = (app) ->

    shortcuts = require './helpers/shortcut'
    express   = require 'express'

    # all environements
    app.use express.bodyParser
        uploadDir: './uploads'
        keepExtensions: true

    # extend express to DRY controllers
    app.use shortcuts

    #test environement
    app.configure 'test', ->

    #development environement
    app.configure 'development', ->
        app.use express.logger 'dev'
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    #production environement
    app.configure 'production', ->
        app.use express.logger()
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    # static middleware
    app.use express.static __dirname + '/../client/public',
        maxAge: 86400000
