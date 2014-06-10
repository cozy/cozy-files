BaseView = require '../lib/base_view'
Modal = require "./modal"
Helpers = require '../lib/folder_helpers'
File = require '../models/file'
ModalUploadView = require './modal_upload'

Client = require "../helpers/client"

# extends the cozy-clearance modal to files specifics
module.exports = class ModalFolderView extends Modal

    id: "dialog-new-folder"
    className: "modal fade"
    attributes:
        'tab-index': -1
    template: require './templates/modal_folder'

    constructor: (options, callback) ->

        # must be done first, otherwise it's undefined
        @uploadingFiles = options.uploadingFiles

        # do not use modal short constructor
        Modal.__super__.constructor.apply this, arguments
        @callback = callback
        @validator = options.validator


    events: ->
        _.extend super,
            'keyup #inputName' : 'onKeyUp'
            'change #folder-uploader': 'onUploaderChange'


    initialize: ->
        super
        @prefix = @model.repository()

    # - display upload folder form only if it is supported
    # - Register submit button
    afterRender: ->
        uploadDirectoryInput = @$("#folder-uploader")[0]
        supportsDirectoryUpload = uploadDirectoryInput.directory or
                                  uploadDirectoryInput.mozdirectory or
                                  uploadDirectoryInput.webkitdirectory or
                                  uploadDirectoryInput.msdirectory

        if supportsDirectoryUpload
            @$("#folder-upload-form").removeClass('hide')


        @uploader = @$('#folder-uploader')
        @inputName = @$('#inputName')

        @submitButton = @$ "#modal-dialog-yes"
        @$el.on 'show', @onShow

        # @submitButton.spin()
        # @showModal()

    hideAndDestroy: =>
        @hide()
        setTimeout =>
            @destroy()
        , 500

    onShow: =>
        setTimeout =>
            @inputName.focus()
        , 500

    onKeyUp: (event) =>
        if event.keyCode is 13 #enter
            event.preventDefault()
            event.stopPropagation()
            @onYes()
        else
            # make action clear
            @action = 'create'
            @uploader.val ''
            if @inputName.val().length > 0
                @enableCreateButtonState()
            else
                @disableCreateButtonState()

    onUploaderChange: =>
        # make action clear
        @action = 'upload'
        @inputName.val ''
        @enableCreateButtonState()

    enableCreateButtonState: ->
        element = $ '#modal-dialog-yes'
        if element.prop 'disabled'
            element.prop('disabled', 'false').button 'refresh'

    disableCreateButtonState: ->
        element = $ '#modal-dialog-yes'
        unless element.prop 'disabled'
            element.prop 'disabled', 'true'

    doSaveFolder: (folder, callback) ->
        # let parent view decide if this exists
        if err = @validator folder
            return Modal.error t "modal error folder exists"

        @submitButton.html('&nbsp;').spin('tiny')
        folder.save null,
            always: ->
                @submitButton.spin(false).text t 'new folder send'

            success: (data) =>
                @hideAndDestroy()
                callback null

            error: (_, err) ->
                if err.status is 400
                    Modal.error t "modal error folder exists"
                else
                    Modal.error t "modal error folder create"

                callback err

    doCreateFolder: (callback) =>
        folder = new File
            name: @$('#inputName').val()
            path: @prefix
            type: "folder"

        if errors = folder.validate()
            return Modal.error t "modal error no data"

        @doSaveFolder folder, callback


    doUploadFolder: (callback) =>
        files = @$('#folder-uploader')[0].files

        if not files.length
            return Modal.error t "modal error no data"

        dirs = Helpers.nestedDirs files

        async.each dirs, (dir, cb) =>
            dir = Helpers.removeTralingSlash dir
            parts = dir.split '/'
            path = "#{@prefix}/#{parts[...-1].join '/'}"
            path = Helpers.removeTralingSlash path


            folder = new File
                name: parts[-1..][0]
                path: path
                type: "folder"

            @doSaveFolder folder, (err) ->
                console.log err if err
                cb null

        , (err) =>

            files = _.filter files, (file) ->
                file.name not in ['.', '..']

            for file in files
                relPath = file.relativePath or
                          file.mozRelativePath or
                          file.webkitRelativePath or
                          file.msRelativePath
                file.path = "#{@prefix}/#{Helpers.dirName relPath }"

            new ModalUploadView
                files: files
                validator: -> null
                uploadingFiles: @uploadingFiles


    onYes: =>
        doStuff = if @action is 'upload' then @doUploadFolder else @doCreateFolder

        doStuff ->
            console.log arguments
