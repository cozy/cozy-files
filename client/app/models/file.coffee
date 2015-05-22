client = require '../lib/client'

###

Represent a file or folder document.


# Local state and Shared state.
There is a concept of local state and shared state in the application, it is
handled in this class.

The local state corresponds to the state of the client that is not shared
with other clients through websockets.

The shared state is shared with other clients through websockets.

Both are needed in order to support various features like conflict management,
upload cancel, or broken file detection.

# View state.
The state "selected" is only relevant into the view, but it's handy to manage
it in the model.
###
module.exports = class File extends Backbone.Model

    # The breadcrumb is an array of vanilla JS objects
    # representing a parent folder.
    breadcrumb: []

    # Local state. Handled through `markAs*` and `is*` methods.
    uploadStatus: null

    # Local state. Handled through `markAsErrored` method.
    error: null

    # View state. Handled through *viewSelected
    viewSelected: false

    # Valid values for `uploadStatus`.
    @VALID_STATUSES: [null, 'uploading', 'uploaded', 'errored', 'conflict']

    constructor: (options) ->
        doctype = options.docType?.toLowerCase()
        if doctype? and doctype in ['file', 'folder']
            options.type = doctype

        super options


    # Helpers. @TODO DUPLICATE OF GETREPOSITORY.
    getPath: ->
        path = @get 'path'
        path = "/#{path}" if (path.length > 0) and (path[0] isnt '/')
        name = @get 'name'
        return "#{path}/#{name}"

    isFolder: -> return @get('type') is 'folder'
    isFile: -> return @get('type') is 'file'
    isSearch: -> return @get('type') is 'search'
    isRoot: -> return @get('id') is 'root'

    hasBinary: -> return @isFile() and @get('binary')?.file?.id?
    isBroken: -> return @isFile() and not @hasBinary() and not @get('uploading')

    ###
        Getters for the local state.
    ###
    isUploading: -> return @isFile() and @uploadStatus is 'uploading'
    isUploaded: -> return @isFile() and @uploadStatus is 'uploaded'
    isErrored: -> return @isFile() and @uploadStatus is 'errored'
    isConflict: -> return @uploadStatus is 'conflict'
    inUploadCycle: ->
        return @isUploading() or @isUploaded() or @isErrored() or @isConflict()

    ###
        Setters for the local state. Semantic wrapper for _setUploadStatus.
    ###
    markAsUploading: -> @_setUploadStatus 'uploading'
    markAsUploaded: -> @_setUploadStatus 'uploaded'
    markAsConflict: -> @_setUploadStatus 'conflict'
    markAsErrored: (error) -> @_setUploadStatus 'errored', error
    resetStatus: ->
        @overwrite = null
        @_setUploadStatus null

    ###
        Trigger change for each status update because Backbone only triggers
        `change` events for model's attributes.
        The `change` events allow the projection to be updated.

        @param `status` must be in File.VALID_STATUSES
    ###
    _setUploadStatus: (status, error = null) ->
        if status not in File.VALID_STATUSES
            message = "Invalid upload status #{status} not " + \
                      "in #{File.VALID_STATUSES}"
            throw new Error message
        else
            @error = error
            @uploadStatus = status
            @trigger 'change', @


    # Solve a conflict by either marking the model with the resolution result
    # or resuming the queue processing.
    solveConflict: (choice) ->
        # if the model is already in the queue, we trigger the process to get
        # the queue going.
        if @processOverwrite?
            @processOverwrite choice
            @processOverwrite = null

        # otherwise, just mark the resolution result so the queue can process
        # the item by itself.
        else
            @overwrite = choice


    ###
        Getter for the shared state.
    ###
    isServerUploading: -> return @get('uploading') and not @inUploadCycle()



    ###
        Manage view state.
        The state "selected" is only relevant into the view, but it's handy
        to manage it in the model.
    ###
    isViewSelected: -> return @viewSelected


    toggleViewSelected: (isShiftPressed = false) ->
        @setSelectedViewState not @isViewSelected(), isShiftPressed


    setSelectedViewState: (viewSelected, isShiftPressed = false) ->
        @viewSelected = viewSelected
        @trigger 'toggle-select', isShiftPressed


    # Remove server's additional information
    parse: (data) ->
        delete data.success
        return data

    # the repository is the model's full path (name included in the path)
    getRepository: ->
        if @isRoot() then "" else "#{@get('path')}/#{@get('name')}"

    # Overrides sync method to allow file upload (multipart request)
    # and progress events
    sync: (method, model, options) =>


        # this is a new model, let's upload it as a multipart
        if model.file

            # if the file is being overwritten (update), we force
            # the "create" method, since only the "create" action in the server
            # can handle file upload.
            method = 'create'
            @id = ""

            formdata = new FormData()
            formdata.append 'name', model.get 'name'
            formdata.append 'path', model.get 'path'
            formdata.append 'lastModification', model.get 'lastModification'
            formdata.append 'overwrite', true if @overwrite
            formdata.append 'file', model.file

            # trigger upload progress on the model
            progress = (e) ->
                model.loaded = e.loaded
                model.trigger 'progress', e

            _.extend options,
                contentType: false
                data: formdata
                # patch Model.sync so it could trigger progress event
                xhr: =>
                    xhr = $.ajaxSettings.xhr()
                    if xhr.upload
                        xhr.upload.addEventListener 'progress', progress, false
                        @uploadXhrRequest = xhr
                    xhr

        Backbone.sync.apply @, arguments

    urlRoot: ->
        prefix = if app.isPublic then '../' else ''

        if @isFolder()
            prefix + 'folders/'
        else if @isSearch()
            prefix + 'search/'
        else
            prefix + 'files/'

    # Overrides the url method to append the key if it's public mode
    url: (toAppend = '') ->
        url = super()
        key = if app.isPublic then window.location.search else ''

        return url + toAppend + key

    getPublicURL: (key) ->
        link = "#{app.domain}#{@urlRoot()}#{@id}"
        if @isFile()
            name = encodeURIComponent @get 'name'
            link = "#{link}/attach/#{name}"
        return link

    # Only relevant if model is a folder
    getZipURL: ->
        if @isFolder()
            toAppend = "/zip/#{encodeURIComponent @get 'name'}"
            @url toAppend

    # Only relevant if model is a file
    getAttachmentUrl: ->
        # if the file is being uploaded, it's not accessible (yet)
        if @isUploading()
            "#"
        else if @isFile()
            toAppend = "/attach/#{encodeURIComponent @get 'name'}"
            @url toAppend

    getDownloadUrl: ->
        if @isFile()
            toAppend = "/download/#{encodeURIComponent @get 'name'}"
            @url toAppend
        else if @isFolder()
            @getZipURL()

    validate: (attrs) ->
        errors = []
        if not attrs.name or attrs.name is ''
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

    ###
        ONLY RELEVANT IF IT'S A FOLDER
        Fetches content (folders and files) for the current folder
        the request also responds with the breadcrumb
    ###
    fetchContent: (callbacks) ->
        @prepareCallbacks callbacks

        url = "#{@urlRoot()}content"
        key = window.location.search # relevant if shared mode
        if app.isPublic and not @isSearch()
            url = "#{@urlRoot()}#{@id}/content#{key}"
        else if @isSearch()
            url += key

        client.post url, id: @id, (err, body) =>
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

                @setBreadcrumb parents or []
                callbacks null, content, parents

    # Set the breadcrumb attribute and append the root model to it
    # If the folder is a search query, the breadcrumb is the query
    setBreadcrumb: (parents) ->
        if @get('type') is 'search'
            @breadcrumb = [window.app.root.toJSON(), @toJSON()]
        else
            parents.unshift window.app.root.toJSON()
            # adds the current folder to the parent's list unless it's the root
            parents.push @toJSON() unless @isRoot()
            @breadcrumb = parents

    getClearance: ->
        if app.isPublic
            return null
        else
            inheritedClearance = @get 'inheritedClearance'
            if not inheritedClearance or inheritedClearance.length is 0
                return @get 'clearance'
            else
                return inheritedClearance[0].clearance
