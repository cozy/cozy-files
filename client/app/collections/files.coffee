File = require '../models/file'

###
Represents a collection of files
It acts as the cache when instantiate as the baseCollection
The base collection holds ALL the files and folders of the application
It creates projections (subcollection) that will be consumed by folder views.
Those projections represents one folder.
###
module.exports = class FileCollection extends Backbone.Collection

    # Model that will be contained inside the collection.
    model: File

    # This is where ajax requests the backend.
    url: 'files'

    cachedPaths: []

    isPathCached: (path) -> @cachedPaths.indexOf(path) isnt -1

    ###
        Retrieves folder's information (meta data)
        * from memory if it's cached
        * otherwise, from server
    ###
    getFolderInfo: (folderID, callback) ->
        folder = @get folderID
        unless folder?
            #console.log "fetch folder info"
            folder = new File id: folderID, type: "folder"
            folder.fetch
                success: =>
                    @add folder
                    callback null, folder
                error: (xhr, resp) ->
                    callback status: resp.status, msg: resp.statusText
        else
            #console.log "[cache] fetch folder info"
            callback null, folder

    # Retrieves folder's content (files and folders in it)
    getFolderContent: (folder, callback = ->) ->
        #console.log "fetch folder content"
        path = folder.getRepository()
        folder.fetchContent (err, content, parents) =>
            if err?
                callback err
            else
                #folder.setBreadcrumb parents
                @add content, merge: true

                @cachedPaths.push path unless @isPathCached path
                callback()

    ###
        Global method to retrieve folder's info and content
        and create a subcollection (projection) based on the current collection
    ###
    getByFolder: (folderID, callback) ->
        @getFolderInfo folderID, (err, folder) =>
            if err? then callback err
            else
                path = folder.getRepository()
                filter = (file) ->
                    file.get('path') is path and not file.isRoot()

                collection = new BackboneProjections.Filtered @,
                                    filter: filter
                                    comparator: @comparator

                if @isPathCached path
                    #console.log "[cache] fetch folder content"
                    callback null, folder, collection
                else
                    # we retrieve at the same time the folder's content
                    # and the folder's breadcrumb
                    @getFolderContent folder, ->
                        callback null, folder, collection

    comparator: (o1, o2) ->

        # default values
        @type = 'name' unless @type?
        @order = 'incr' unless @order?

        if @type is 'name'
            n1 = o1.get('name').toLocaleLowerCase()
            n2 = o2.get('name').toLocaleLowerCase()
        else if @type is "lastModification"
            n1 = new Date(o1.get 'lastModification')
            n2 = new Date(o2.get 'lastModification')
        else
            n1 = o1.get @type
            n2 = o2.get @type

        t1 = o1.get 'type'
        t2 = o2.get 'type'

        sort = if @order is 'incr' then -1 else 1

        if t1 is t2
            if n1 > n2 then return -sort
            if n1 < n2 then return sort
            return 0
        else if t1 is "file"
            return -sort
        else
            return sort
