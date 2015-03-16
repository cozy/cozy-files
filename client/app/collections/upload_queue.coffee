File = require '../models/file'
Helpers = require '../lib/folder_helpers'

# the uploadQueue is a mix of async.queue & BackoneCollection
# blobs are added to the queue & to the collection
# on upload success, File Models are marked as loaded
# on

module.exports = class UploadQueue

    # number of files actually loaded
    loaded: 0

    # list of paths where files are being uploaded
    uploadingPaths: {}


    constructor: (@baseCollection) ->
        @uploadCollection = @baseCollection.getFilesBeingUploaded()


        # Backbone.Events is a mixin, not a "class" you can extend.
        _.extend @, Backbone.Events

        @asyncQueue = async.queue @uploadWorker, 5
        @listenTo @uploadCollection, 'sync error', @onSyncError
        @listenTo @uploadCollection, 'progress', _.throttle =>
            @trigger 'upload-progress', @computeProgress()
        , 100

        @asyncQueue.drain = @completeUpload


    reset: ->
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

        # copy the collection because resetStatus triggers change events which
        # updates the uploadCollection, resulting in elements not being
        # processed in the loop
        collection = @uploadCollection.toArray()
        collection.forEach (model) -> model.resetStatus()

        @trigger 'reset'

    # Handle request's abort
    abort: (model) =>
        model.uploadXhrRequest.abort()
        @remove model
        if model.isNew() then model.destroy()


    # Remove a model from the upload queue
    remove: (model) ->
        @loaded++
        model.resetStatus()
        window.pendingOperations.upload--


    # Add a model to the upload queue
    add: (model) ->

        window.pendingOperations.upload++

        # don't override conflict status
        model.markAsUploading() unless model.isConflict()

        # if the model is not new, it don't add it
        @baseCollection.add model

        # Files at the end, folders at the beginning
        if model.get('type') is 'file'

            # we add the conflictual models at the end so the upload
            # can start without waiting for user input.
            if model.isConflict()
                @asyncQueue.push model
            else
                @asyncQueue.unshift model

        else if model.get('type') is 'folder'
            @asyncQueue.unshift model
        else
            throw new Error('adding wrong typed model to upload queue')


    # Reset variables and trigger completion events.
    completeUpload: =>
        window.pendingOperations.upload = 0
        @completed = true
        @loaded = 0
        @trigger 'upload-complete'


    # When an upload completes or fails, we keep counts.
    onSyncError: (model) =>
        path = model.get('path') + '/'
        @uploadingPaths[path]--
        @loaded++


    # Process each element from the queue
    uploadWorker: (model, next) =>
        # Skip if there is an error.
        if model.error
            setTimeout next, 10

        # If there is a conflict, the queue waits for the user to
        # make a decision.
        else if model.isConflict()
            # The bind() method creates a new function that, when called, has
            # its 'this' keyword set to the provided value (first argument),
            # with a given sequence of arguments preceeding any provided when
            # the new function is called.
            model.processOverwrite = @_decideOn.bind @, model, next

        # Otherwise, the upload starts directly.
        else
            @_processSave model, next


    # In case of conflict, change the queue based on user choice
    _decideOn: (model, done, choice) ->
        model.overwrite = choice
        if choice
            model.markAsUploading()
            @_processSave model, done
        else
            model.resetStatus()
            @remove model
            done()


    # Perform the actual persistence by saving the model and changing
    # uploadStatus based on response. If there is an unexpected error, it tries
    # again 3 times before failing.
    _processSave: (model, done) ->

        # double check that we don't try to upload something we know will fail
        if not model.isConflict() and not model.isErrored()
            model.save null,
                success: (model) ->
                    model.file = null
                    # to make sure progress is uniform, we force it at 100%
                    model.loaded = model.total
                    model.markAsUploaded()
                    done null
                error: (_, err) =>
                    model.file = null
                    body = try JSON.parse(err.responseText)
                    catch e then msg: null

                    # This case may occur when two clients upload a file
                    # with the same name at the same time in the same
                    # folder. Thus we just show a warning
                    if err.status is 400 and body.code is 'EEXISTS'
                        model.markAsErrored body

                    else if err.status is 400 and body.code is 'ESTORAGE'
                        model.markAsErrored body


                    # Retry if an unexpected error occurs
                    else
                        model.tries = 1 + (model.tries or 0)
                        if model.tries > 3
                            defaultMessage = "modal error file upload"
                            model.error = t err.msg or defaultMessage
                            errorKey = err.msg or defaultMessage
                            error = t errorKey
                            model.markAsErrored error
                        else
                            # let's try again
                            @asyncQueue.push model

                    done()
        else
            done()


    addBlobs: (blobs, folder) ->
        @reset() if @completed

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

            model.file = blob
            model.loaded = 0
            model.total = blob.size

            # mark as errored if it's a folder
            if blob.size is 0 and blob.type.length is 0
                model.error = 'Cannot upload a folder with Firefox'
                # since there is an error, the progressbar cannot compute
                # the progress if those properties are not set
                model.total = 0
                model.file = null
                @trigger 'folderError', model

            # mark as in conflict with existing file
            else if (existingModel = @isFileStored(model))?

                # update data
                existingModel.set
                    size: blob.size
                    lastModification: blob.lastModifiedDate

                existingModel.file = blob
                existingModel.loaded = 0
                existingModel.total = blob.size

                model = existingModel

                model.markAsConflict()
                @trigger 'conflict', model


            @add model
            @markPathAsUploading model

            setTimeout nonBlockingLoop, 2


    addFolderBlobs: (blobs, parent) ->
        @reset() if @completed

        dirs = Helpers.nestedDirs blobs
        i = 0
        do nonBlockingLoop = =>

            # if no more folders to add, leave the loop
            unless dir = dirs[i++]
                # folders will be created
                # we can safely add files to bottom of queue
                blobs = _.filter blobs, (blob) -> blob.name not in ['.', '..']
                @addBlobs blobs, parent
                return

            prefix = parent.getRepository()
            parts = Helpers.getFolderPathParts dir
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
            @markPathAsUploading folder

            setTimeout nonBlockingLoop, 2


    # Export usable stats about the upload
    getResults: ->
        errorList = []
        existingList = []
        success = 0

        @uploadCollection.each (model) ->
            if model.isErrored()
                error = model.error
                if error.code is 'EEXISTS'
                    existingList.push model
                else
                    errorList.push model

                console.log "Upload Error", model.getRepository(), error
            else
                success++

        status = if errorList.length then 'error'
        else if existingList.length then 'warning'
        else 'success'

        return {status, errorList, existingList, success}


    # Keep track of models being uploaded by path
    markPathAsUploading: (model) ->
        # appending a / prevents conflict with elements
        # having the same prefix in their names
        path = "#{model.get 'path'}/"
        unless @uploadingPaths[path]?
            @uploadingPaths[path] = 0

        @uploadingPaths[path]++


    # Return the number of children elements being uploading for a given path
    getNumUploadingElementsByPath: (path) ->
        # appending a / prevents conflict with elements
        # having the same prefix in their names
        path = "#{path}/"

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
        iter = (sum, model) -> return sum + model[prop]
        return @uploadCollection.reduce iter, 0


    # Returns an existing model if a file with a similar id or a similar
    # location (path + name) is already in the queue.
    isFileStored: (model) ->
        return @baseCollection.isFileStored model
