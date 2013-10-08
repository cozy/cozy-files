File = require '../models/file'

module.exports = class FileCollection extends Backbone.Collection

    # Model that will be contained inside the collection.
    model: File

    # This is where ajax requests the backend.
    url: 'files'

    # patch Model.sync so it could trigger progress event
    sync: (method, model, options)->
        progress = (e)->
            model.trigger('progress', e)

        _.extend options,
            xhr: ()->
                xhr = $.ajaxSettings.xhr()
                if xhr instanceof window.XMLHttpRequest
                    xhr.addEventListener 'progress', progress, false
                if xhr.upload
                    xhr.upload.addEventListener 'progress', progress, false
                xhr

        Backbone.sync.apply @, arguments