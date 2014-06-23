module.exports = class UploadQueue extends Backbone.Collection

    # number of files actually loaded
    loaded: 0

    initialize: ->
        @listenTo @, 'sync', =>
            @loaded++
            @trigger 'upload-progress', loaded: @loaded, total: @length

    isAllLoaded: -> return @loaded is @length

    reset: (models, options) ->
        @loaded = 0
        super models, options

    processUpload: (callback) ->
        # do upload 5 by 5
        toUpload = @filter (file) -> return not file.isUploaded
        async.eachLimit toUpload, 5, (file, cb) ->

            # we really make sure that an uploaded file won't be upload again
            return cb null  if file.error or file.isUploaded

            file.save null,
                success: -> cb null
                error: (err) ->
                    file.error = t err.msg or "modal error file upload"
                    file.trigger 'sync'
                    cb null # do not stop all list if one fail
        , callback
