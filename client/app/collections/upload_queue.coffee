File = require '../models/file'
Helpers = require '../lib/folder_helpers'

# the uploadQueue is a mix of async.queue & BackoneCollection
# blobs are added to the queue & to the collection
# on upload success, File Models are marked as loaded
# on

module.exports = class UploadQueue extends Backbone.Collection

    loaded: 0 # number of files actually loaded
    uploadingPaths: {} # list of paths where files are being uploaded


    add: (models, options) ->
        # if model doesn't exist, it's a reset so we don't increment
        window.pendingOperations.upload++ if models?

        @reset() if @completed
        super models, options


    reset: (models, options) ->
        # sets the progress to 0% so next upload initial progress is 0% instead
        # of 100%
        @progress =
            loadedFiles: 0
            totalFiles: @length
            loadedBytes: 0
            totalBytes: @sumProp 'total'

        window.pendingOperations.upload = 0

        @loaded = 0
        @completed = false
        @uploadingPaths = {}
        super


    initialize: ->
        @asyncQueue = async.queue @uploadWorker, 5

        @listenTo this, 'add', @onAdd
        @listenTo this, 'remove', @onRemove
        @listenTo this, 'sync error', @onSyncError
        @listenTo this, 'progress', _.throttle =>
            @trigger 'upload-progress', @computeProgress()
        , 100

        @asyncQueue.drain = @completeUpload


    # Never happens, but should be handled
    onRemove: (model) =>
        model.error = 'aborted'


    # When an upload completes or fails, we keep counts
    onSyncError: (model) =>
        path = model.get('path') + '/'
        @uploadingPaths[path]--
        @loaded++


    # when a model is added, we queue it for upload
    onAdd: (model) =>
        @completed = false

        # This model is marked for being uploaded.
        model.isUploaded = false

        # Files at the bottom, Folder at the top
        if model.get('type') is 'file'

            # we add the conflictual models at the end so the upload
            # can start without waiting for user input
            if model.conflict
                @asyncQueue.push model
            else
                @asyncQueue.unshift model

        else if model.get('type') is 'folder'
            @asyncQueue.unshift model
        else
            throw new Error('adding wrong typed model to upload queue')


    # Reset variables and trigger completion events
    completeUpload: =>
        window.pendingOperations.upload = 0
        @completed = true
        @loaded = 0
        @trigger 'upload-complete'


    uploadWorker: (model, callback) =>
        if model.existing or model.error
            setTimeout callback, 10
        else
            processSave = (model) ->

                if not model.conflict or model.conflict and model.overwrite
                    model.save null,
                        success: (model) ->
                            model.file = null
                            model.isUploaded = true
                            model.loaded = model.total
                            unless app.baseCollection.get(model.id)
                                app.baseCollection.add model
                            callback null
                        error: (_, err) =>
                            model.file = null
                            body = try JSON.parse(err.responseText)
                            catch e then msg: null

                            # This case may occur when two clients upload a file
                            # with the same name at the same time in the same
                            # folder. Thus we just show a warning
                            if err.status is 400 and body.code is 'EEXISTS'
                                model.existing = true
                                return callback new Error body.msg

                            if err.status is 400 and body.code is 'ESTORAGE'
                                model.error = new Error body.msg
                                return callback model.error

                            model.tries = 1 + (model.tries or 0)
                            if model.tries > 3
                                defaultMessage = "modal error file upload"
                                model.error = t err.msg or defaultMessage
                            else
                                # let's try again
                                @asyncQueue.push model

                            callback err
                else
                    callback()

            # If there is a conflict, the queue waits for the user to
            # make a decision.
            if model.conflict and not model.overwrite?
                model.processSave = processSave.bind @

            # Otherwise, the upload starts directly
            else
                processSave.call @, model


    addBlobs: (blobs, folder) ->

        i = 0
        existingPaths = app.baseCollection.existingPaths()
        # we do a non blocking loop, handling one file every 2ms so the
        # UI don't get stuck
        do nonBlockingLoop = =>
            return unless blob = blobs[i++]

            path = folder.getRepository() or ''
            relPath = blob.relativePath or
                blob.mozRelativePath or
                blob.webkitRelativePath or
                blob.msRelativePath

            # Adds sub folder in the path if it's uploaded by a parent folder
            if relPath and (subDir = Helpers.dirName relPath).length > 0
                path += "/#{subDir}"

            model = new File
                type: 'file'
                class: 'document'
                size: blob.size
                name: blob.name
                path: path
                lastModification: blob.lastModifiedDate

            # mark as errored if it's a folder
            if blob.size is 0 and blob.type.length is 0
                model.error = 'Cannot upload a folder with Firefox'
                @trigger 'folderError', model
                # since there is an error, the progressbar cannot compute
                # the progress if those properties are not set
                model.loaded = 0
                model.total = 0

            else if model.getRepository() in existingPaths
                model.conflict = true
                @trigger 'conflict', model
                model.file = blob
                model.loaded = 0
                model.total = blob.size

            else
                model.file = blob
                model.loaded = 0
                model.total = blob.size

            @add model
            @markAsUploading model

            setTimeout nonBlockingLoop, 2


    addFolderBlobs: (blobs, parent) ->

        dirs = Helpers.nestedDirs blobs
        i = 0
        do nonBlockingLoop = =>

            # if no more folders to add, leave the loop
            unless dir = dirs[i++]
                # folders will be created
                # we can safely add files to bottom of queue
                blobs = _.filter blobs, (blob) ->
                    blob.name not in ['.', '..']
                @addBlobs blobs, parent
                return

            prefix = parent.getRepository()
            parts = dir.split('/').filter (x) -> x # ?remove empty last part
            name = parts[parts.length - 1]
            path = [prefix].concat(parts[...-1]).join '/'

            folder = new File
                type: "folder"
                name: name
                path: path

            folder.loaded = 0
            folder.total = 250 # ~ size of the query

            # add folder to be saved
            @add folder
            @markAsUploading folder

            setTimeout nonBlockingLoop, 2


    filteredByFolder: (folder, comparator) ->
        filteredUploads = new BackboneProjections.Filtered this,
            filter: (file) ->
                return file.get('path') is folder.getRepository() and
                    not file.isUploaded

            comparator: comparator


    getResults: ->
        error = []
        existing = []
        success = 0
        skipped = 0

        @each (model) ->
            if model.error
                console.log "Upload Error", model.getRepository(), model.error
                error.push model
            else if model.existing then existing.push model

            # file that were conflict and not overwritten are marked as skipped
            else if model.conflict and not model.overwrite then skipped++
            else success++

        status = if error.length then 'error'
        else if existing.length then 'warning'
        else 'success'

        return {status, error, existing, success, skipped}


    # we keep track of models being uploaded by path
    markAsUploading: (model) ->
        # appending a / prevents conflict with elements
        # having the same prefix in their names
        path = model.get('path') + '/'
        unless @uploadingPaths[path]?
            @uploadingPaths[path] = 0

        @uploadingPaths[path]++


    # returns the number of children elements being uploading for a given path
    getNumUploadingElementsByPath: (path) ->
        # appending a / prevents conflict with elements
        # having the same prefix in their names
        path = path + '/'

        return _.reduce @uploadingPaths, (memo, value, index) ->
            if index.indexOf(path) isnt -1 or path is ''
                return memo + value
            else
                return memo
        , 0


    # Recalculate progress
    computeProgress: =>
        return @progress =
            loadedFiles: @loaded
            totalFiles: @length
            loadedBytes: @sumProp 'loaded'
            totalBytes: @sumProp 'total'


    # Add all values for a given property.
    sumProp: (prop) =>
        iter = (sum, model) -> sum + model[prop]
        @reduce iter, 0

