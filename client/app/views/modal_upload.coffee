Modal = require './modal'
File = require '../models/file'
ProgressBar = require './progressbar'

UploadedFileView = require './uploaded_file_view'

module.exports = class ModalUploadView extends Modal

    id: "dialog-upload-file"
    className: "modal fade"
    attributes:
        'tab-index': -1
    template: require './templates/modal_upload'

    events: ->
        _.extend super,
            'dragover':  'onDragEnter'
            'dragenter': 'onDragEnter'
            'dragleave': 'onDragLeave'
            'drop':      'onDrop'
            'change #uploader': 'onUploaderChange'
            'mousedown #uploader': 'handleUploaderActive'

    constructor: (options, callback) ->
        # must be done first, otherwise it's undefined
        @uploadingFiles = options.uploadingFiles

        # do not use modal short constructor
        Modal.__super__.constructor.apply this, arguments
        @callback = callback
        @validator = options.validator
        @files = options.files

        @views = {}

        @onYes() if @files?.length > 0

    initialize: ->
        @listenTo @uploadingFiles, 'add', @afterRender
        @listenTo @uploadingFiles, 'progress-total', =>
            @totalProgress.trigger 'progress',
                loaded: @uploadingFiles.loaded
                total: @uploadingFiles.length

            # Force the refresh if all uploads are done
            @afterRender() if @uploadingFiles.loaded is @uploadingFiles.length

        super()

    afterRender: =>
        @input = @$ '#uploader input'
        @label = @$ '#uploader .text'

        # files are being uploaded
        if @uploadingFiles.length > 0
            # hide what must be hidden
            noButton = $ '#modal-dialog-no'
            noButton.html '&nbsp;'
            noButton.spin 'small'

            @subRenderTotalProgressBar()
            @subRenderFileUploadProgress()

            # when upload is over, we reset the modal
            if @uploadingFiles.loaded is @uploadingFiles.length
                noButton = $ '#modal-dialog-no'
                noButton.spin false
                noButton.html t 'upload end button'
                @uploadingFiles.reset()
                @uploadingFiles.loaded = 0

    subRenderTotalProgressBar: ->
        @$('#progress-total').empty()
        @views = []
        @totalProgress = new Backbone.Model name: t 'total progress'
        @totalProgress.loaded = @uploadingFiles.loaded
        @totalProgress.total = @uploadingFiles.length
        progressbar = new ProgressBar(model: @totalProgress).render()
        progressbar.$el.prependTo @$ '#progress-total'

    subRenderFileUploadProgress: ->
        @$('#progress-part').empty()
        filesEl =  []
        # first we detach the existing views (better performance)
        _.map Object.keys(@views), (viewID) => @views[viewID].$el.detach()

        # next we create or reattach existing views
        @uploadingFiles.forEach (uploadingFile) =>
            uploadView = @views[uploadingFile.cid]

            unless uploadView?
                uploadEl = new UploadedFileView model: uploadingFile
                @views[uploadingFile.cid] = uploadEl

            @$('#progress-part').append uploadEl.render().$el

    onNo: ->
        @input.val ""
        @hide()
        setTimeout (() => @destroy()), 500

    onYes: -> @doUploadFiles => @callback?()

    handleUploaderActive: =>
        @$('#uploader').addClass 'active'
        $(document).one 'mouseup', =>
            @$('#uploader').removeClass 'active'

    updateMessage: =>
        if @files.length
            msg = t 'upload msg selected', smart_count: @files.length
            $('#modal-dialog-yes').prop "disabled", false
        else
            msg = t 'upload msg'
            $('#modal-dialog-yes').prop "disabled", true

        @label.text msg

    onUploaderChange: (e) =>
        @files = @input[0].files
        @updateMessage()

    onDragEnter: (e) ->
        e.preventDefault()
        e.stopPropagation()
        @$('.modal-body').css 'background-color', 'yellow'

    onDragLeave: (e) ->
        e.preventDefault()
        e.stopPropagation()
        @$('.modal-body').css 'background-color', ''

    onDrop: (e) =>
        e.preventDefault()
        e.stopPropagation()

        @files = _.filter e.dataTransfer.files, (attach) -> attach.type isnt ''
        @updateMessage()


    doUploadFiles: (callback) =>
        # first loop, create models & progress bars
        filesModels = _.map @files, (blob) =>
            fileModel = new File
                type: 'file'
                name: blob.name
                path: blob.path or @model.repository()
                lastModification: blob.lastModifiedDate
            fileModel.file = blob
            fileModel.loaded = 0
            fileModel.total = blob.size
            fileModel.error = @validator fileModel

            @uploadingFiles.add fileModel

            return fileModel

        # we clear the input to allow simultaneous uploads
        @files = []
        @input.val ""
        @updateMessage()

        # second loop, do upload 5 by 5
        async.eachLimit filesModels, 5, (fileModel, cb) ->
            return cb null if fileModel.error
            fileModel.save null,
                success: -> cb null
                error: (err) ->
                    fileModel.error = t err.msg or "modal error file upload"
                    fileModel.trigger 'sync'
                    cb null # do not stop all list if one fail
        , callback

    destroy: ->
        @stopListening @uploadingFiles
        super()
