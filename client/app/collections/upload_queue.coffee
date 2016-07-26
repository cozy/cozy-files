File    = require '../models/file'
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

        # Create a collection for elements to be processed by the queue. This
        # information is not based on the base collection for performance
        # reasons (it doesn't have to be updated each time a big folder is
        # loaded.)
        @uploadCollection = new Backbone.Collection()


        # Backbone.Events is a mixin, not a "class" you can extend.
        _.extend @, Backbone.Events

        @asyncQueue = async.queue @uploadWorker, 5
        @listenTo @uploadCollection, 'sync error', @onSyncError
        @listenTo @uploadCollection, 'progress', _.throttle =>
            @trigger 'upload-progress', @computeProgress()
        , 100

        @asyncQueue.drain = @completeUpload.bind @


    reset: ->
        # sets the progress to 0% so next upload initial progress is 0% instead
        # of 100%
        @progress =
            loadedBytes: 0
            totalBytes: @sumProp 'total'

        window.pendingOperations.upload = 0

        @completed = false
        @uploadingPaths = {}

        # Copy the collection because resetStatus triggers `change` events which
        # updates the uploadCollection, resulting in elements not being
        # processed by the loop (the iterator breaks).
        collection = @uploadCollection.toArray()
        collection.forEach (model) =>
            @uploadCollection.remove model
            model.resetStatus()

        @trigger 'reset'

    # Handle request's abort
    abort: (model) =>
        model.uploadXhrRequest.abort()
        @remove model
        if model.isNew() then model.destroy()


    # Remove a model from the upload queue
    remove: (model) ->
        model.resetStatus()
        window.pendingOperations.upload--


    # Add a model to the upload queue
    add: (model) ->

        window.pendingOperations.upload++

        # don't override conflict status
        model.markAsUploading() unless model.isConflict()

        # Add the model to the base collection so it can be added in the list.
        @baseCollection.add model

        # Add the model to the upload queue so it can be processed.
        @uploadCollection.add model

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
        @trigger 'upload-complete'


    # When an upload completes or fails, we keep counts.
    onSyncError: (model) =>
        path = model.get('path') + '/'
        @uploadingPaths[path]--


    # Process each element from the queue
    uploadWorker: (model, next) =>
        # Skip if there is an error.
        if model.error
            setTimeout next, 10

        # If there is a conflict, the queue waits for the user to
        # make a decision.
        else if model.isConflict()
            # Wait for user input through conflict resolution modal if it's not
            # already done.
            unless model.overwrite?
                # The bind() method creates a new function that, when called,
                # has its 'this' keyword set to the provided value
                # (first argument), with a given sequence of arguments
                # preceeding any provided when the new function is called.
                model.processOverwrite = @_decideOn.bind @, model, next

            # Or process the item if the user has made a choice.
            else
                @_decideOn model, next, model.overwrite

        # Otherwise, the upload starts directly.
        else
            @_processSave model, next


    # In case of conflict, change the queue based on user choice.
    _decideOn: (model, done, choice) ->
        # Mark the model as being overwritten (or not) so it knows during upload
        # if it must tell the server to overwrite (or not).
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
                success: (model) =>
                    model.file = null
                    # To make sure progress is uniform, we force it at 100%.
                    model.loaded = model.total
                    model.markAsUploaded()

                    # Update the upload paths so folders now when they don't
                    # have upload inside them anymore.
                    @unmarkPathAsUploading model

                    done null
                error: (_, err) =>
                    model.file = null
                    body = try JSON.parse(err.responseText)
                    catch e then msg: null

                    # This case may occur when two clients upload a file
                    # with the same name at the same time in the same
                    # folder. It can also accur when uploading an existing
                    # folder.
                    if err.status is 400 and body.code is 'EEXISTS'
                        model.markAsErrored body

                    else if err.status is 400 and body.code is 'ESTORAGE'
                        model.markAsErrored body

                    else if err.status is 0 and err.statusText is 'error'
                        # abort by user, don't try again

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

            # In Firefox, folders are empty files without mime type, so an error
            # is triggered to the user.
            # In all browsers, empty files without a mime type are unfortunately
            # caught by this condition, resulting in an error. See #209.
            if blob.size is 0 and blob.type.length is 0

                # The element should not be added to the queue
                model = null

                # Let the view know something went wrong.
                @trigger 'folderError'

            # mark as in conflict with existing file
            else if (existingModel = @isFileStored(model))?

                # if the model is currently in the upload process (except if
                # it's been successfully uploaded), it's not added.
                if not existingModel.inUploadCycle() or existingModel.isUploaded()
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
                else
                    # Prevent the file from being added to the queue.
                    model = null


            if model?
                @add model
                @markPathAsUploading model

            setTimeout nonBlockingLoop, 2


    addFolderBlobs: (blobs, parent) ->
        @reset() if @completed

        dirs = Helpers.nestedDirs blobs
        i = 0
        isConflict = false
        do nonBlockingLoop = =>

            # if no more folders to add, leave the loop
            dir = dirs[i++]
            unless dir

                # Only add the files if there are no conflict.
                unless isConflict
                    # Folders will be created, files can safely be added at the
                    # end of the queue.
                    blobs = _.filter blobs, (blob) ->
                        return blob.name not in ['.', '..']
                    @addBlobs blobs, parent

            else
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

                # If the folder already exists, nothing is done because
                # the overwrite management is not good in that case.
                if (existingModel = @isFileStored(folder))?
                    # This will end the nonBlockingLoop.
                    i = dirs.length
                    isConflict = true
                    @trigger 'existingFolderError', existingModel
                else
                    # Add folder to be saved to the queue.
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
                if error?.code is 'EEXISTS'
                    existingList.push model
                else
                    errorList.push model

                console.log "Upload Error", model.getRepository(), error
            else if model.isUploaded()
                # otherwise, user has canceled upload
                success++

        status = if errorList.length then 'error'
        else if existingList.length then 'warning'
        else 'success'

        return {status, errorList, existingList, success}


    # Keep track of models being uploaded by path.
    markPathAsUploading: (model) ->
        # Appending a / prevents conflict with elements
        # having the same prefix in their names.
        path = "#{model.get 'path'}/"
        unless @uploadingPaths[path]?
            @uploadingPaths[path] = 0

        @uploadingPaths[path]++


    # Remove the mark on the folder.
    unmarkPathAsUploading: (model) ->
        # Appending a / prevents conflict with elements
        # having the same prefix in their names.
        path = "#{model.get 'path'}/"

        @uploadingPaths[path]--


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
