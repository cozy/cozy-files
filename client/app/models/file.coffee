client = require '../lib/client'

module.exports = class File extends Backbone.Model

    # The breadcrumb is an array of vanilla JS objects
    # representing a parent folder.
    breadcrumb: null

    constructor: (options) ->
        doctype = options.docType?.toLowerCase()
        if doctype?
            options.type = if doctype is 'file' then 'file' else 'folder'
        super options

    isFolder: -> return @get('type') is 'folder'
    isRoot: -> return @get('id') is 'root'

    # Overrides sync method to allow file upload (multipart request)
    # and progress events
    sync: (method, model, options)->

        # this is a new model, let's upload it as a multipart
        if model.file
            formdata = new FormData()
            formdata.append 'name', model.get 'name'
            formdata.append 'path', model.get 'path'
            formdata.append 'file', model.file
            formdata.append 'lastModification', model.get 'lastModification'

            # trigger upload progress on the model
            progress = (e) -> model.trigger 'progress', e

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

    # DEPRECATED -- alias due to deprecation
    repository: -> @getRepository()
    getRepository: ->
        if @get('id') is "root"
            return ""
        else
            return "#{@get("path")}/#{@get("name")}"

    getPublicURL: (key) ->
        "#{window.location.origin}/public/files/#{@urlRoot()}#{@id}"

    ###
        ONLY RELEVANT IF IT'S A FOLDER
        Fetches content (folders and files) for the current folder
        the request also responds with the breadcrumb
    ###
    fetchContent: (callbacks) ->
        @prepareCallbacks callbacks
        client.post "#{@urlRoot()}content", id: @id, (err, body) =>
            if err?
                @setBreadcrumb []
                callbacks err
            else
                if body.parents?
                    {content, parents} = body
                else
                    # during search or for root, there is not parents
                    content = body
                    parents = []
                @setBreadcrumb parents
                callbacks null, content, parents

    # Set the breadcrumb attribute and append the root model to it
    # If the folder is a search query, the breadcrumb is the query
    setBreadcrumb: (parents) ->
        if @get('type') is 'search'
            @breadcrumb = [window.app.root.toJSON(), @toJSON()]
        else
            parents.unshift window.app.root.toJSON()
            @breadcrumb = parents
