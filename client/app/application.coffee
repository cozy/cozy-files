FileCollection = require './collections/files'
BreadcrumbsManager = require "./collections/breadcrumbs"
File = require './models/file'

FolderView = require './views/folder'

module.exports =

    initialize: ->
        # Used in inter-app communication
        #SocketListener = require '../lib/socket_listener'

        # Routing management
        Router = require 'router'
        @router = new Router()
        @breadcrumbs = new BreadcrumbsManager()

        # the root
        @root = new File id:"root", path:"", name:"", isFolder:true
        # and the folder view
        @folderView = new FolderView @root, @breadcrumbs

        el = @folderView.render().$el
        $('body').append el

        Backbone.history.start()

        # for easy debugging in browser
        window.app = @

        # Makes this object immuable.
        Object.freeze this if typeof Object.freeze is 'function'