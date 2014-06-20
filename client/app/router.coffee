app = require 'application'
File = require './models/file'
FileCollection = require './collections/files'
FolderView = require './views/folder'

###
Binds routes to code actions.
This is also used as a controller to initialize views and perform data fetching
###
module.exports = class Router extends Backbone.Router

    folderView: null

    routes:
        '': 'main'
        'folders/:folderid' : 'folder'
        'search/:query' : 'search'

    main: ->
        rootID = app.root.get 'id'
        @_loadFolderView rootID

    folder: (id) -> @_loadFolderView id

    search: (query) ->
        folder = new File
                id: query
                type: "search"
                name: "#{t('breadcrumbs search title')} '#{query}'"

        folder.fetchContent (err, content) =>
            collection = new FileCollection content

            # we don't re-render the view to prevent the search field
            # from being reset
            if @folderView?
                @folderView.updateSearch folder, collection
            else
                @_renderFolderView folder, collection, query

    # get the data and render the view
    _loadFolderView: (folderID) ->
        # add the spinner during folder change
        @folderView.spin() if @folderView?

        # retrieve folder info and content from data source or cache
        app.baseCollection.getByFolder folderID, (err, folder, collection) =>
            if err? then console.log err
            else
                @_renderFolderView folder, collection

    # process the actual render
    _renderFolderView: (folder, collection, query = '') ->
        if @folderView?
            @folderView.destroy()
            # because destroying the view also removes the element
            $('html').append $ '<body></body>'

        @folderView = new FolderView
            model: folder
            collection: collection
            baseCollection: app.baseCollection
            breadcrumbs: app.breadcrumbs
            uploadQueue: app.uploadQueue
            query: query
        @folderView.render()
