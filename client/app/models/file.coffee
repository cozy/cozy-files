client = require "../helpers/client"

module.exports = class File extends Backbone.Model

    sync: (method, model, options)->

        # this is a new model, let's upload it as a multipart
        if model.file
            formdata = new FormData()
            formdata.append 'name', model.get 'name'
            formdata.append 'path', model.get 'path'
            formdata.append 'file', model.file
            formdata.append 'lastModification', model.get 'lastModification'

            # trigger upload progress on the model
            progress = (e) -> model.trigger('progress', e)

            _.extend options,
                contentType: false
                data: formdata
                # patch Model.sync so it could trigger progress event
                xhr: ->
                    xhr = $.ajaxSettings.xhr()
                    if xhr instanceof window.XMLHttpRequest
                        xhr.addEventListener 'progress', progress, false
                    if xhr.upload
                        xhr.upload.addEventListener 'progress', progress, false
                    xhr

        @isUploaded = true
        Backbone.sync.apply @, arguments

    urlRoot: ->
        if @get("type") is "folder"
            'folders/'
        else if @get("type") is "search"
            'search/'
        else
            'files/'

    validate: ->
        errors = []
        if not @get("name") or @get("name") is ""
            errors.push
                field: 'name'
                value: "A name must be set."

        if errors.length > 0
            return errors
        return

    prepareCallbacks: (callbacks, presuccess, preerror) ->
        {success, error} = callbacks or {}
        presuccess ?= (data) => @set data.app
        @trigger 'request', @, null, callbacks
        callbacks.success = (data) =>
            presuccess data if presuccess
            @trigger 'sync', @, null, callbacks
            success data if success
        callbacks.error = (jqXHR) =>
            preerror jqXHR if preerror
            @trigger 'error', @, jqXHR, {}
            error jqXHR if error

    repository: ->
        if @get('id') is "root"
            return ""
        else
            return "#{@get("path")}/#{@get("name")}"

    endpoint: ->
        if @get("type") is "folder"
            "foldershare"
        else
            "fileshare"

    # FOLDER
    findContent: (callbacks) ->
        @prepareCallbacks callbacks
        client.post "#{@urlRoot()}content", id: @id, callbacks

    findFiles: (callbacks) ->
        @prepareCallbacks callbacks
        client.post "#{@urlRoot()}files", id: @id, callbacks

    findFolders: (callbacks) ->
        @prepareCallbacks callbacks
        client.post "#{@urlRoot()}folders", id: @id, callbacks

    getPublicURL: (key) ->
        "#{window.location.origin}/public/files/#{@urlRoot()}#{@id}"

    getZip: (file, callbacks) ->
        @prepareCallbacks callbacks
        client.post "#{@urlRoot()}#{@id}/zip/#{@name}", callbacks

    # FILE
    getAttachment: (file, callbacks) ->
        @prepareCallbacks callbacks
        client.post "#{@urlRoot()}#{@id}/getAttachment/#{@name}", callbacks
