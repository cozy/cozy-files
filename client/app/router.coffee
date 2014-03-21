app = require 'application'

FolderView = require './views/folder'
File = require './models/file'


module.exports = class Router extends Backbone.Router

    routes:
        '': 'main'
        'folders/:folderid' : 'folder'
        'search/:query' : 'search'

    main: ->
        app.folderView.changeActiveFolder app.root

    folder: (id) ->
        folder = new File id:id, type:"folder"
        folder.fetch
            success: (data) =>
                folder.set data
                app.folderView.changeActiveFolder folder

    search: (query) ->
        folder = new File id:query, type:"search", name: "Search '#{query}'"
        app.folderView.changeActiveFolder folder
