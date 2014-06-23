Modal = require './modal'
File = require '../models/file'
ProgressBar = require '../widgets/progressbar'

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
        @uploadQueue = options.uploadQueue

        # do not use modal short constructor
        Modal.__super__.constructor.apply this, arguments
        @callback = callback
        @validator = options.validator
        @files = options.files

        @views = {}

        @onYes() if @files?.length > 0

    initialize: ->
        @listenTo @uploadQueue, 'add', @afterRender
        @listenTo @uploadQueue, 'upload-progress', (progress) =>
            @totalProgress.trigger 'progress', progress

            # Force the refresh if all uploads are done
            @afterRender() if @uploadQueue.isAllLoaded()

        super()

    afterRender: =>
        @input = @$ '#uploader input'
        @label = @$ '#uploader .text'

        # files are being uploaded
        if @uploadQueue.length > 0
            # hide what must be hide
            noButton = $ '#modal-dialog-no'
            noButton.html '&nbsp;'
            noButton.spin 'small'

            @subRenderTotalProgressBar()
            @subRenderFileUploadProgress()

            # when upload is over, we reset the modal
            if @uploadQueue.isAllLoaded()
                noButton = $ '#modal-dialog-no'
                noButton.spin false
                noButton.html t 'upload end button'
                @uploadQueue.reset()

    subRenderTotalProgressBar: ->
        @$('#progress-total').empty()
        @views = []
        @totalProgress = new Backbone.Model()
        @totalProgress.loaded = @uploadQueue.loaded
        @totalProgress.total = @uploadQueue.length

        progressbar = new ProgressBar(model: @totalProgress).render()
        $("<span>#{t('total progress')}</span>").appendTo @$ '#progress-total'
        progressbar.$el.appendTo @$ '#progress-total'

    subRenderFileUploadProgress: ->
        @$('#progress-part').empty()
        filesEl =  []
        # first we detach the existing views (better performance)
        _.map Object.keys(@views), (viewID) => @views[viewID].$el.detach()

        # next we create or reattach existing views
        @uploadQueue.forEach (uploadingFile) =>
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
        # file models are created based on form content
        models = _.map @files, (blob) =>
            fileModel = new File
                type: 'file'
                name: blob.name
                path: blob.path or @model.getRepository()
                lastModification: blob.lastModifiedDate
            fileModel.file = blob
            fileModel.loaded = 0
            fileModel.total = blob.size
            fileModel.error = @validator fileModel
            return fileModel
        @uploadQueue.add models
        @uploadQueue.processUpload callback

        # input is cleared to allow simultaneous uploads
        @files = []
        @input.val ""
        @updateMessage()

    destroy: ->
        @stopListening @uploadQueue
        super()
