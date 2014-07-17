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
        'click a.file-delete'      : 'onDeleteClicked'
        'click a.file-share'       : 'onShare'
        'click a.file-edit'        : 'onEditClicked'
        'click a.file-edit-save'   : 'onSaveClicked'
        'click a.file-edit-cancel' : 'onCancelClicked'
        'click a.file-move'        : 'onMoveClicked'
        'keydown input.file-edit-name'  : 'onKeyPress'
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
        'image/png'                    : 'fa-image'
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
            isBeingUploaded: @model.isBeingUploaded()
            attachmentUrl: @model.getAttachmentUrl()
            downloadUrl: @model.getDownloadUrl()

    initialize: (options) ->
        @isSearchMode = options.isSearchMode
        @listenTo @model, 'change', @refresh
        @listenTo @model, 'request', =>
            @$('.spinholder').spin 'small'
        @listenTo @model, 'sync error', =>
            @$('.spinholder').spin false

        # prevent contacts loading in shared area
        unless app.isPublic
            ModalShareView ?= require "./modal_share"

        # If the model is a folder, we listen to the upload queue to enable or
        # disable the "something is being uploaded in my tree" indicator
        if @model.isFolder()
            uploadQueue = options.uploadQueue
            path = @model.getRepository()
            numUploadChildren = uploadQueue.getNumUploadingElementsByPath path
            @hasUploadingChildren = numUploadChildren > 0

            @listenTo uploadQueue, 'add remove reset', =>
                hasItems = uploadQueue.getNumUploadingElementsByPath(path) > 0
                @$('.fa-folder').toggleClass 'spin', hasItems

            @listenTo uploadQueue, 'upload-complete', =>
                @hasUploadingChildren = false
                @$('.fa-folder').removeClass 'spin'

    refresh: ->

        changes = Object.keys @model.changed

        if changes.length is 1
            if changes[0] is 'tags'
                return # only tags has changed, TagsView handle it

            if changes[0] is 'lastModification'
                # this change often, let's not re-render the whole view
                date = moment(@model.changed.lastModification).calendar()
                @$('td.date-column-cell span').text date
                return

        # more complex change = rerender
        @render()


    displayError: (msg) ->
        @errorField ?= $('<span class="error">').insertAfter @$('.tags')
        if msg is false then @errorField.hide()
        else @errorField.text msg

    onDeleteClicked: ->
        new ModalView t("modal are you sure"), t("modal delete msg"), t("modal delete ok"), t("modal cancel"), (confirm) =>
            if confirm
                @model.destroy
                    error: ->
                        ModalView.error t("modal delete error")

    onEditClicked: ->
        width = @$(".caption").width() + 10
        model = @model.toJSON()
        model.class = 'folder' unless model.class?
        @$el.html @templateEdit model: model
        @tags = new TagsView
            el: @$ '.tags'
            model: @model
        @tags.render()
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
            range.moveEnd "character", lastIndexOfDot
            range.moveStart "character", 0
            range.select()

        @$el.addClass 'edit-mode'

    onShare: -> new ModalShareView model: @model

    onSaveClicked: ->
        name = @$('.file-edit-name').val()

        if name and name isnt ""
            @$el.removeClass 'edit-mode'
            @model.save name: name,
                wait: true,
                success: (data) =>
                    @render()
                error: (model, err) =>
                    @$('.file-edit-name').focus()
                    @displayError if err.status is 400 then t 'modal error in use'
                    else t 'modal error rename'

        else
            @displayError t("modal error empty name")

    onCancelClicked: ->
        @$el.removeClass 'edit-mode'
        if @model.isNew() then @model.destroy()
        else @render()



    # Display Move widget and handle move operation if user confirms.
    onMoveClicked: =>
        formTemplate = """
            <div class="move-widget">
            <span> #{t 'move element to'}: </span>
            <select class="move-select"></select>
            <button class="button btn move-btn">
                #{t 'move'}
            </button>
            <button class="btn btn-link cancel-move-btn">
                #{t 'cancel'}
            </button>
            </div>
        """

        errorTemplate = """
            <div>
                <span class="error">
                #{'error occured while moving element'}: #{@model.get 'name'}.
                #</span>
            </div>
        """

        movedTemplate = (path) ->
            """
            <div id="moved-infos">
            <span>#{ t 'file successfully moved to'}: /#{path}.</span>
            <button class="btn btn-link cancel-move-btn">
                #{t 'cancel'}
            </button>
            </div>
        """

        optionTemplate =  (path) -> """
            <option value="#{path}">#{path}</option>
        """

        firstCell = @$el.find 'td:first-child'

        client.get 'folders/list', (err, paths) =>
            if err
                Modal.error err
            else
                parentPath = @model.get 'path'
                fullPath =  @model.getRepository()
                type = @model.get 'type'

                # Add root folder to list.
                paths.push '/' if parentPath isnt  ""


                # Fill folder combobox with folder list.
                moveForm = $ formTemplate
                for path in paths
                    if path isnt parentPath \
                       and not(type is 'folder' and path.indexOf(fullPath) is 0)
                        moveForm.find('select').append optionTemplate path

                # Cancel move action on cancel clicked.
                cancelButton =  moveForm.find(".cancel-move-btn")
                cancelButton.click ->
                    moveForm.remove()

                # Perform move operation on move clicked.
                moveButton = moveForm.find(".move-btn")
                moveButton.click =>

                    # Show loading
                    moveButton.html t "moving..."

                    # Get path and url information.
                    path = $(".move-select").val().substring 1
                    id = @model.get 'id'
                    previousPath = @model.get 'path'

                    # Stop render sync.
                    @stopListening @model
                    window.app.socket.pause @model, null,
                        ignoreMySocketNotification: true

                    showMoveResult = =>
                        moveForm.fadeOut()
                        moveForm.remove()
                        movedInfos = $ movedTemplate path
                        firstCell.append movedInfos
                        cancelButton =  movedInfos.find(".cancel-move-btn")
                        movedInfos.click =>
                            data = path: previousPath
                            client.put "#{type}s/#{id}", data, (err) =>
                                if err
                                    ModalView.error t 'error occured canceling move'
                                else
                                    movedInfos.fadeOut()

                    # Can't use Backbone model due to a weird sync
                    # I can't figure out what is causing view to re-render.
                    client.put "#{type}s/#{id}", path: path, (err) =>
                        if err
                            firstCell.append errorTemplate
                        else
                            showMoveResult()

                        # Put back synchronization.
                        window.app.socket.resume @model, null,
                            ignoreMySocketNotification: true
                        @listenTo @model, 'change', @render

                @$el.find('td:first-child').append moveForm


    onKeyPress: (e) =>
        if e.keyCode is 13
            @onSaveClicked()
        else if e.keyCode is 27
            @render()

    onSelectChanged: (event) ->
        isChecked = $(event.target).is ':checked'
        @$el.toggleClass 'selected', isChecked
        @model.isSelected = isChecked
        return true

    afterRender: ->
        # if the file is being uploaded
        if @model.isBeingUploaded()
            @$('.type-column-cell').remove()
            @$('.date-column-cell').remove()
            @progressbar = new ProgressBar(model: @model)
            cell = $('<td colspan="2"></td>')
            cell.append @progressbar.render().$el
            @$('.size-column-cell').after cell
            # we don't want the file link to react
            @$('a.caption.btn').click (event) -> event.preventDefault()
        else
            @tags = new TagsView
                el: @$('.tags')
                model: @model
            @tags.render()

        # if it's a folder and if it has children being uploaded
        if @hasUploadingChildren
            @$('.fa-folder').addClass 'spin'
