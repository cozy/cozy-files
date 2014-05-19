Modal = require './modal'
File = require '../models/file'
ProgressBar = require './progressbar'

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
        # do not use modal short constructor
        Modal.__super__.constructor.apply this, arguments
        @callback = callback
        @validator = options.validator

        @files = options.files

        @onYes() if @files?.length > 0

    afterRender: =>
        @input = @$ '#uploader input'
        @label = @$ '#uploader .text'

    onNo: ->
        @input.val ""
        @hide()
        setTimeout (() => @destroy()), 500

    onYes: ->
        noButton = $ '#modal-dialog-no'
        noButton.html '&nbsp;'
        noButton.spin 'small'
        @$('fieldset, #modal-dialog-yes').hide()
        @doUploadFiles =>
            @input.val ""
            noButton.spin false
            noButton.html t 'upload end button'
            @callback?()

    handleUploaderActive: =>
        @$('#uploader').addClass 'active'
        $(document).one 'mouseup', =>
            @$('#uploader').removeClass 'active'

    updateMessage: =>
        msg = if @files.length
            t 'upload msg selected', smart_count: @files.length
        else
            t 'upload msg'

        $('#modal-dialog-yes').prop("disabled", "false").button 'refresh'
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

        @isUploading = true
        @totalProgress = new Backbone.Model name: t 'total progress'
        progressbar = new ProgressBar(@totalProgress).render()
        progressbar.$el.prependTo @$ '.modal-body'

        # first loop, create models & progress bars
        filesEl = _.map @files, (blob) =>
            fileModel = new File
                type: 'file'
                name: blob.name
                path: blob.path or @model.repository()
                lastModification: blob.lastModifiedDate
            fileModel.file = blob
            fileModel.loaded = 0
            fileModel.total = blob.size

            fileModel.error = @validator fileModel
            fileModel.on 'progress', (e) =>
                console.log "PROGRESS EVENT", e.loaded/e.total
                fileModel.loaded = e.loaded
                fileModel.total = e.total
                @updateTotalProgress(filesEl)

            return @createProgressBlock fileModel

        # second loop, do upload 5 by 5
        async.eachLimit filesEl, 5, (fileEl, cb) =>
            return cb null if fileEl.model.error
            fileEl.model.save null,
                success: =>
                    @displayMessage 'success', fileEl, t 'upload success'
                    cb null
                error: (err) =>
                    msg = t err.msg or "modal error file upload"
                    @displayMessage 'error', fileEl, msg
                    cb null # do not stop all list if one fail

        , callback


    displayMessage: (type, $el, msg) ->
        $el.bar?.remove()
        $el.append """
            <span class="#{type}">#{msg}</span>
        """

    updateTotalProgress: (files) ->
        loaded = total = 0
        for fileEl in files when fileEl.model.error is null
            loaded += fileEl.model.loaded
            total += fileEl.model.total
        @totalProgress.trigger 'progress', {loaded, total}


    createProgressBlock: (model) ->
        $file = $ """
            <div class="progress-name">
                <span class="name">#{model.get('name')}</span>
            </div>"""
        $file.model = model
        if model.error
            $file.append '<span class="error"> : ' + model.error + '</span>'
        else
            $file.append $file.bar = new ProgressBar(model).render().$el


        $file.appendTo @$('.modal-body')
        return $file