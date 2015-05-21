BaseView = require '../lib/base_view'
ModalView = require "./modal"
ModalShareView = null
TagsView = require "../widgets/tags"
ProgressBar = require '../widgets/progressbar'

client = require "../lib/client"

module.exports = class FileView extends BaseView

    className      : 'folder-row'
    tagName        : 'tr'
    templateNormal : require './templates/file'
    templateEdit   : require './templates/file_edit'
    templateSearch : require './templates/file_search'

    events:
        'click a.file-tags': 'onTagClicked'
        'click a.file-delete': 'onDeleteClicked'
        'click a.file-share': 'onShareClicked'
        'click a.file-edit': 'onEditClicked'
        'click a.file-edit-save': 'onSaveClicked'
        'click a.file-edit-cancel': 'onCancelClicked'
        'click a.cancel-upload-button': 'onCancelUploadClicked'
        'click a.file-move': 'onMoveClicked'
        'click a.broken-button': 'onDeleteClicked'
        'keydown input.file-edit-name': 'onKeyPress'
        'change input.selector': 'onSelectChanged'

    mimeClasses:
        'application/octet-stream'      : 'fa-file-o'
        'application/x-binary'          : 'fa-file'
        'text/plain'                    : 'fa-file-text-o'
        'text/richtext'                 : 'fa-file-text-o'
        'application/x-rtf'             : 'fa-file-text-o'
        'application/rtf'               : 'fa-file-text-o'
        'application/msword'            : 'fa-file-word-o'
        'application/mspowerpoint'      : 'fa-file-powerpoint-o'
        'application/vnd.ms-powerpoint' : 'fa-file-powerpoint-o'
        'application/x-mspowerpoint'    : 'fa-file-powerpoint-o'
        'application/excel'             : 'fa-file-excel-o'
        'application/x-excel'           : 'fa-file-excel-o'
        'aaplication/vnd.ms-excel'      : 'fa-file-excel-o'
        'application/x-msexcel'         : 'fa-file-excel-o'
        'application/pdf'               : 'fa-file-pdf-o'
        'text/html'                     : 'fa-file-code-o'
        'text/asp'                      : 'fa-file-code-o'
        'text/css'                      : 'fa-file-code-o'
        'application/x-javascript'      : 'fa-file-code-o'
        'application/x-lisp'            : 'fa-file-code-o'
        'application/xml'               : 'fa-file-code-o'
        'text/xml'                      : 'fa-file-code-o'
        'application/x-sh'              : 'fa-file-code-o'
        'text/x-script.python'          : 'fa-file-code-o'
        'application/x-bytecode.python' : 'fa-file-code-o'
        'text/x-java-source'            : 'fa-file-code-o'
        'application/postscript'        : 'fa-image'
        'image/gif'                     : 'fa-image'
        'image/jpg'                     : 'fa-image'
        'image/jpeg'                    : 'fa-image'
        'image/pjpeg'                   : 'fa-image'
        'image/x-pict'                  : 'fa-image'
        'image/pict'                    : 'fa-image'
        'image/png'                     : 'fa-image'
        'image/x-pcx'                   : 'fa-image'
        'image/x-portable-pixmap'       : 'fa-image'
        'image/x-tiff'                  : 'fa-image'
        'image/tiff'                    : 'fa-image'
        'audio/aiff'                    : 'fa-file-audio-o'
        'audio/x-aiff'                  : 'fa-file-audio-o'
        'audio/midi'                    : 'fa-file-audio-o'
        'audio/x-midi'                  : 'fa-file-audio-o'
        'audio/x-mid'                   : 'fa-file-audio-o'
        'audio/mpeg'                    : 'fa-file-audio-o'
        'audio/x-mpeg'                  : 'fa-file-audio-o'
        'audio/mpeg3'                   : 'fa-file-audio-o'
        'audio/x-mpeg3'                 : 'fa-file-audio-o'
        'audio/wav'                     : 'fa-file-audio-o'
        'audio/x-wav'                   : 'fa-file-audio-o'
        'video/avi'                     : 'fa-file-video-o'
        'video/mpeg'                    : 'fa-file-video-o'
        'application/zip'               : 'fa-file-archive-o'
        'multipart/x-zip'               : 'fa-file-archive-o'
        'multipart/x-zip'               : 'fa-file-archive-o'
        'application/x-bzip'            : 'fa-file-archive-o'
        'application/x-bzip2'           : 'fa-file-archive-o'
        'application/x-gzip'            : 'fa-file-archive-o'
        'application/x-compress'        : 'fa-file-archive-o'
        'application/x-compressed'      : 'fa-file-archive-o'
        'application/x-zip-compressed'  : 'fa-file-archive-o'
        'multipart/x-gzip'              : 'fa-file-archive-o'


    template: (args) ->
        if @isSearchMode
            @templateSearch args
        else
            @templateNormal args


    getRenderData: ->
        _.extend super(),
            isUploading: @model.isUploading()
            isServerUploading: @model.isServerUploading()
            isBroken: @model.isBroken()
            attachmentUrl: @model.getAttachmentUrl()
            downloadUrl: @model.getDownloadUrl()
            clearance: @model.getClearance()


    initialize: (options) ->
        @isSearchMode = options.isSearchMode
        @uploadQueue = options.uploadQueue
        @listenTo @model, 'change', @refresh
        @listenTo @model, 'sync error', =>
            # For overwritten files, render entirely to show
            # modification date and type. Render folders unless they are in
            # an errored state.
            if @model.isConflict() or (@model.isFolder() and not @isErrored)
                @render()

        @listenTo @model, 'toggle-select', @onToggleSelect

        # prevent contacts loading in shared area
        unless app.isPublic
            ModalShareView ?= require "./modal_share"

        # If the model is a folder, we listen to the upload queue to enable or
        # disable the "something is being uploaded in my tree" indicator
        if @model.isFolder()
            path = @model.getRepository()
            numUploadChildren = @uploadQueue.getNumUploadingElementsByPath path
            @hasUploadingChildren = numUploadChildren > 0

            @listenTo @uploadQueue, 'add remove reset', =>
                hasItems = @uploadQueue.getNumUploadingElementsByPath(path) > 0
                if hasItems and not @$('.spinholder').is ':visible'
                    @showLoading()
                else if not hasItems and @$('.spinholder').is ':visible'
                    @hideLoading()

            @listenTo @uploadQueue, 'upload-complete', =>
                @hasUploadingChildren = false
                @hideLoading()


    refresh: ->
        changes = Object.keys @model.changed

        if changes.length is 1
            if changes[0] is 'tags'
                return # only tags has changed, TagsView handle it

        # more complex change = rerender
        @render()


    displayError: (message) ->

        cancelButton =  @$ '.file-edit-cancel'
        @errorField ?= $('<span class="error">').insertAfter cancelButton

        if message isnt false
            @errorField.text message
            @errorField.show()
            @isErrored = true
        else
            @errorField.hide()
            @isErrored = false


    onTagClicked: ->
        @tags.toggleInput()


    onDeleteClicked: ->
        new ModalView t("modal are you sure"), t("modal delete msg"), t("modal delete ok"), t("modal cancel"), (confirm) =>
            if confirm
                window.pendingOperations.deletion++
                @model.destroy
                    success: -> window.pendingOperations.deletion--
                    error: ->
                        window.pendingOperations.deletion--
                        ModalView.error t "modal delete error"


    onEditClicked: (name) ->

        width = @$(".caption").width() + 10
        model = @model.toJSON()
        model.class = 'folder' unless model.class?

        if typeof(name) is "string"
            model.name = name

        @$el.html @templateEdit
            model: model
            clearance: @model.getClearance()

        @$(".file-edit-name").width width
        @$(".file-edit-name").focus()

        # we only want to select the part before the file extension
        lastIndexOfDot = model.name.lastIndexOf '.'
        lastIndexOfDot = model.name.length if lastIndexOfDot is -1
        input = @$(".file-edit-name")[0]

        if typeof input.selectionStart isnt "undefined"
            input.selectionStart = 0
            input.selectionEnd = lastIndexOfDot
        else if document.selection && document.selection.createRange
            # IE Branch...
            input.select()
            range = document.selection.createRange()
            range.collapse true
            range.moveStart "character", 0
            range.moveEnd "character", lastIndexOfDot
            range.select()

        @$el.addClass 'edit-mode'


    onShareClicked: ->
        new ModalShareView model: @model


    onSaveClicked: ->
        name = @$('.file-edit-name').val()

        # Prevent empty names (with spaces only).
        name = name?.trim()

        # If the name has not changed, reset the view state.
        if name and name is @model.get('name')
            @onCancelClicked()

        # If the input is not empty, start the update process.
        else if name and name isnt ""
            @$el.removeClass 'edit-mode'

            # Show the loading indicator.
            @showLoading()

            # Hide the previous error in case there was one.
            @displayError false

            # Prevent re-submit/cancel during the save request.
            @undelegateEvents()

            # Mark submit/cancel buttons as disabled during the request.
            @$('a.btn').addClass 'disabled'

            # Pause the realtime during the request, because sometimes the
            # realtime notification is received and processed by the client,
            # before the request's response to the `save` request. It leads to
            # a duplication of the model (two models with the exact same
            # attributes), and as a result, in the UI.
            options = ignoreMySocketNotification: true
            window.app.socket.pause @model, null, options

            @model.save name: name,
                wait: true,
                success: (data) =>

                    # Resume the realtime, now the response has been received.
                    window.app.socket.resume @model, null, options

                    # Hide the loading indicator.
                    @hideLoading()

                    # Re-enable events handling for the view.
                    @delegateEvents()

                    # Render will remove the edit form, and display the folder
                    # properly.
                    @render()

                error: (model, err) =>

                    # Resume the realtime, now the response has been received.
                    window.app.socket.resume @model, null, options

                    # Hide the loading indicator.
                    @hideLoading()

                    # Re-enable submit/cancel buttons for future edit.
                    @$('a.btn').removeClass 'disabled'
                    @delegateEvents()

                    # Focus the input field to allow the user to edit
                    # immediately.
                    @$('.file-edit-name').focus()

                    # Customize the error if status is 400, which means the file
                    # or the folder already exists.
                    if err.status is 400
                        message = t 'modal error in use'
                    else
                        message = t 'modal error rename'

                    @displayError message

        # If the input is empty, show an error.
        else
            @displayError t("modal error empty name")


    onCancelClicked: ->
        @$el.removeClass 'edit-mode'

        # If it's a new folder, cancel should stop the creation.
        if @model.isNew()
            @model.destroy()

        # Otherwise, the edition mode is just disabled.
        else
            @render()


    # Cancel current upload. Then display a notification that the upload has
    # been canceled for two seconds before removing the whole file line.
    onCancelUploadClicked: ->
        @uploadQueue.abort @model


    onKeyPress: (e) =>
        if e.keyCode is 13 # ENTER key
            @onSaveClicked()
        else if e.keyCode is 27 # ESCAPE key
            @onCancelClicked()


    onSelectChanged: (event) ->
        isChecked = $(event.target).is ':checked'
        @$el.toggleClass 'selected', isChecked
        @model.isSelected = isChecked

        @onToggleSelect()
        return true


    onToggleSelect: ->
        @$el.toggleClass 'selected', @model.isSelected
        @$('input.selector').prop 'checked', @model.isSelected
        if @model.isSelected
            @$('.file-move, .file-delete').addClass 'hidden'
        else
            @$('.file-move, .file-delete').removeClass 'hidden'


    afterRender: ->
        if @model.isUploading() or @model.isServerUploading()
            @$el.addClass 'uploading'
            @addProgressBar()
            @blockDownloadLink()
        else
            @$el.removeClass 'uploading'
            @$el.toggleClass 'broken', @model.isBroken()
            @addTags()


        @hideLoading()
        @showLoading() if @hasUploadingChildren


    # add and display progress bar.
    addProgressBar: ->
        @$('.type-column-cell').remove()
        @$('.date-column-cell').remove()

        @progressbar = new ProgressBar model: @model
        cell = $ '<td colspan="2"></td>'
        cell.append @progressbar.render().$el
        @$('.size-column-cell').after cell


    # Add and display tag widget.
    addTags: ->
        @tags = new TagsView
            el: @$ '.tags'
            model: @model
        @tags.render()
        @tags.hideInput()


    # Make download link inactive.
    blockDownloadLink: ->
        @$('a.caption.btn').click (event) -> event.preventDefault()


    # Show loading spinner.
    showLoading: ->
        @$('.link-wrapper .fa').addClass 'hidden'
        @$('.spinholder').css 'display', 'inline-block'


    # Hide loading spinner.
    hideLoading: ->
        @$('.link-wrapper .fa').removeClass 'hidden'
        @$('.spinholder').hide()
