FolderCollection = require('./collections/folder')
FileCollection = require('./collections/file')


module.exports =

    initialize: ->
        # Used in inter-app communication
        #SocketListener = require '../lib/socket_listener'

        # Routing management
        Router = require 'router'
        @router = new Router()
        @folders = new FolderCollection()
        @files = new FileCollection()
        Backbone.history.start()

        # Makes this object immuable.
        Object.freeze this if typeof Object.freeze is 'function'