File = require '../models/file'
Helpers = require '../lib/folder_helpers'

# the uploadQueue is a mix of async.queue & BackoneCollection
# blobs are added to the queue & to the collection
# on upload success, File Models are marked as loaded
# on

module.exports = class UploadQueue extends Backbone.Collection

    # number of files actually loaded
    loaded: 0

    initialize: ->
        @asyncQueue = async.queue @uploadWorker, 5

        # when a model is added, we queue it for upload
        @listenTo this, 'add', (model) =>
            @completed = false
            @asyncQueue.push model

        # never happens, but should be handled
        @listenTo this, 'remove', (model) =>
            model.error = 'aborted'

        # when an upload complete, we keep counts
        @listenTo this, 'sync', => @loaded++

        # proxy progress events, throttled to every 100ms
        @listenTo this, 'progress', _.throttle =>
            @trigger 'upload-progress', @computeProgress()
        , 100

        # when the queue is totally completed
        @asyncQueue.drain = =>
            @completed = true
            @trigger 'upload-complete'

    add: ->
        @reset() if @completed
        super

    reset: (models, options) ->
        @loaded = 0
        @completed = false
        super

    computeProgress: =>
        return @progress =
            loadedFiles: @loaded
            totalFiles: @length
            loadedBytes: @sumProp 'loaded'
            totalBytes: @sumProp 'total'

    sumProp: (prop) =>
        iter = (sum, model) -> sum + model[prop]
        @reduce iter, 0

    uploadWorker: (model, cb) =>
        if model.existing or model.error or model.isUploaded
            setTimeout cb, 10

        model.save null,
            success: ->
                model.file = null
                model.isUploaded = true
                model.loaded = model.total
                unless app.baseCollection.get model.id
                    app.baseCollection.add model
                cb null
            error: (_, err) =>
                body = try JSON.parse(err.responseText)
                catch e then msg: null

                if err.status is 400 and body.code is 'EEXISTS'
                    model.existing = true
                    return cb new Error body.msg

                if err.status is 400 and body.code is 'ESTORAGE'
                    model.error = new Error body.msg
                    return cb model.error

                model.tries = 1 + (model.tries or 0)
                if model.tries > 3
                    model.error = t err.msg or "modal error file upload"
                else
                    # let's try again
                    @asyncQueue.push model
                cb err

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

            if relPath then path += '/' + Helpers.dirName relPath

            model = new File
                type: 'file'
                class: 'document'
                size: blob.size
                name: blob.name
                path: path
                lastModification: blob.lastModifiedDate

            if model.getRepository() in existingPaths
                model.existing = true
            else
                model.file = blob
                model.loaded = 0
                model.total = blob.size

            @add model

            setTimeout nonBlockingLoop, 2

    addFolderBlobs: (blobs, parent) ->

        for dir in Helpers.nestedDirs(blobs).reverse()
            prefix = parent.getRepository()
            parts = dir.split('/').filter (x) -> x # ?remove empty last part
            name = parts[parts.length - 1]
            path = [prefix].concat(parts[...-1]).join '/'

            folder = new File
                type: "folder"
                name: name
                path: path

            # add folder to be saved (top of queue)
            @asyncQueue.unshift folder

        # Folder will be created, we can safely add files to bottom of queue
        blobs = _.filter blobs, (blob) ->
            blob.name not in ['.', '..']
        @addBlobs blobs, parent

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

        @each (model) ->
            if model.error
                console.log "Upload Error", model.getRepository(), model.error
                error.push model
            else if model.existing then existing.push model
            else success++

        status = if error.length then 'error'
        else if existing.length then 'warning'
        else 'success'

        return {status, error, existing, success}




