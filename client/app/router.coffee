app = require 'application'

FolderView = require './views/folder'
MockupView = require './views/mockup'
File = require './models/file'


module.exports = class Router extends Backbone.Router

    routes:
        '': 'main'
        'folders/:folderid' : 'folder'
        'mockup' : 'mockup'

    main: ->
        app.folderView.changeActiveFolder app.root

    folder: (id) ->
        folder = new File id:id, isFolder:true
        folder.find 
            success: (data) =>
                folder.set data
                app.folderView.changeActiveFolder folder

    mockup: ->
        @displayedView.remove() if @displayedView
        @displayedView = new MockupView()
        @displayedView.render()
