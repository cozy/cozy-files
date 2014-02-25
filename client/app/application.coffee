FileCollection = require './collections/files'
BreadcrumbsManager = require "./collections/breadcrumbs"
File = require './models/file'

FolderView = require './views/folder'

module.exports =

    initialize: ->

        # Routing management
        Router = require 'router'
        @router = new Router()
        @breadcrumbs = new BreadcrumbsManager()

        # Generate the root folder
        @root = new File id:"root", path:"", name:"", type:"folder"

        # and its view
        @folderView = new FolderView
            model: @root
            breadcrumbs: @breadcrumbs
        el = @folderView.render().$el
        $('body').append el

        Backbone.history.start()

        # for easy debugging in browser
        window.app = @

        # Makes this object immuable.
        Object.freeze this if typeof Object.freeze is 'function'
