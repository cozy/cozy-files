BaseView       = require '../lib/base_view'
ModalView      = require "./modal"
ModalShareView = null
TagsView       = require "../widgets/tags"
ProgressBar    = require '../widgets/progressbar'
client         = require "../lib/client"

module.exports = class FileView extends BaseView

    template     : require './templates/file'
    templateEdit : require './templates/file_edit'

    mimeClasses  :
        'application/octet-stream'               : 'type-file'
        'application/x-binary'                   : 'type-binary'
        'text/plain'                             : 'type-text'
        'text/richtext'                          : 'type-text'
        'application/x-rtf'                      : 'type-text'
        'application/rtf'                        : 'type-text'
        'application/msword'                     : 'type-text'
        'application/x-iwork-pages-sffpages'     : 'type-text'
        'application/mspowerpoint'               : 'type-presentation'
        'application/vnd.ms-powerpoint'          : 'type-presentation'
        'application/x-mspowerpoint'             : 'type-presentation'
        'application/x-iwork-keynote-sffkey'     : 'type-presentation'
        'application/excel'                      : 'type-spreadsheet'
        'application/x-excel'                    : 'type-spreadsheet'
        'aaplication/vnd.ms-excel'               : 'type-spreadsheet'
        'application/x-msexcel'                  : 'type-spreadsheet'
        'application/x-iwork-numbers-sffnumbers' : 'type-spreadsheet'
        'application/pdf'                        : 'type-pdf'
        'text/html'                              : 'type-code'
        'text/asp'                               : 'type-code'
        'text/css'                               : 'type-code'
        'application/x-javascript'               : 'type-code'
        'application/x-lisp'                     : 'type-code'
        'application/xml'                        : 'type-code'
        'text/xml'                               : 'type-code'
        'application/x-sh'                       : 'type-code'
        'text/x-script.python'                   : 'type-code'
        'application/x-bytecode.python'          : 'type-code'
        'text/x-java-source'                     : 'type-code'
        'application/postscript'                 : 'type-image'
        'image/gif'                              : 'type-image'
        'image/jpg'                              : 'type-image'
        'image/jpeg'                             : 'type-image'
        'image/pjpeg'                            : 'type-image'
        'image/x-pict'                           : 'type-image'
        'image/pict'                             : 'type-image'
        'image/png'                              : 'type-image'
        'image/x-pcx'                            : 'type-image'
        'image/x-portable-pixmap'                : 'type-image'
        'image/x-tiff'                           : 'type-image'
        'image/tiff'                             : 'type-image'
        'audio/aiff'                             : 'type-audio'
        'audio/x-aiff'                           : 'type-audio'
        'audio/midi'                             : 'type-audio'
        'audio/x-midi'                           : 'type-audio'
        'audio/x-mid'                            : 'type-audio'
        'audio/mpeg'                             : 'type-audio'
        'audio/x-mpeg'                           : 'type-audio'
        'audio/mpeg3'                            : 'type-audio'
        'audio/x-mpeg3'                          : 'type-audio'
        'audio/wav'                              : 'type-audio'
        'audio/x-wav'                            : 'type-audio'
        'video/avi'                              : 'type-video'
        'video/mpeg'                             : 'type-video'
        'video/mp4'                              : 'type-video'
        'application/zip'                        : 'type-archive'
        'multipart/x-zip'                        : 'type-archive'
        'multipart/x-zip'                        : 'type-archive'
        'application/x-bzip'                     : 'type-archive'
        'application/x-bzip2'                    : 'type-archive'
        'application/x-gzip'                     : 'type-archive'
        'application/x-compress'                 : 'type-archive'
        'application/x-compressed'               : 'type-archive'
        'application/x-zip-compressed'           : 'type-archive'
        'application/x-apple-diskimage'          : 'type-archive'
        'multipart/x-gzip'                       : 'type-archive'


    getRenderData: ->
        _.extend super(),
            isUploading       : @model.isUploading()
            isServerUploading : @model.isServerUploading()
            isBroken          : @model.isBroken()
            attachmentUrl     : @model.getAttachmentUrl()
            downloadUrl       : @model.getDownloadUrl()
            clearance         : @model.getClearance()
            isViewSelected    : @model.isViewSelected()


    initialize: (options) ->
        @isSearchMode = options.isSearchMode
        @uploadQueue  = options.uploadQueue

        # prevent contacts loading in shared area
        unless app.isPublic
            ModalShareView ?= require './modal_share'


    beforeRender: ->
        # If the model is a folder, listen to the upload queue to enable or
        # disable the "something is being uploaded in my tree" indicator.
        if @model.isFolder()
            path = @model.getRepository()
            numUploadChildren = @uploadQueue.getNumUploadingElementsByPath path
            @hasUploadingChildren = numUploadChildren > 0
        else
            @hasUploadingChildren = false


    afterRender: ->
        @el.displayMode = 'normal'
        @filePath    = @$ 'a.file-path'
        @elementLink = @$ 'a.link-wrapper'
        @elementName = @elementLink.find '.file-name'
        @thumb       = (@elementLink.find 'img.thumb')[0]
        @elementSize = @$ '.size-column-cell'
        @elementType = @$ '.type-column-cell'
        @elementLastModificationDate = @$ '.date-column-cell'
        @elementIcon = @$ '.icon-type'

        @$el.data('cid', @model.cid) # link between the element and the model
        @$el.addClass('itemRow')

        # all displayed files are in searchMode or none. That's why we can set
        # the line is search mode once for all.
        if @isSearchMode
            @filePath.show()

        # add tags
        @tags = new TagsView
            el   : @$ '.tags'

        # When folders are drag and drop, they can be clicked before being
        # actually created, resulting in an error. Folders don't rely
        # on `isUploading` because it is needless, so they are treated
        # separately.
        @blockNameLink() if @model.isNew()
        @showLoading()   if @hasUploadingChildren
        @reDecorate()


    reDecorate: ->
        # console.log 'reDecorate, displaymode=', @el.displayMode, @isSearchMode

        # by default a line is not on edit mode. If the moved row was in edit
        # mode, just re-render the line not to be in edit mode.
        if @el.displayMode == 'edit'
            @render()
            return

        @beforeRender()

        # get data
        renderData = @getRenderData()
        if @model.isFolder()
            link = "#folders/#{renderData.model.id}"
            size = ''
            type = 'folder'
        else
            if @model.isImage()
                link = renderData.attachmentUrl
            else
                link = renderData.downloadUrl
            size = renderData.model.size or 0
            size = filesize(size, base: 2)
            type = renderData.model.class

        # update path if in search mode
        if @isSearchMode
            @filePath.html @model.attributes.path
            # todo : find the parent folder id to that users can click on path
            # 2 solutions :
            #     get the data from the server for the files (perf...)
            #     get the data only on click : create a special route to point
            #     on the parent, exemple : /files/fileid/parent
            # the first one is less performant and more complex (async)
            # the second gives a path that is not sustainable.
            # @filePath[0].href = "/#folders/" + @model.attributes.parentFolderID

        # update the icon (file or folder or thumbnail)
        if @model.isFolder()
            iconType = 'type-folder'
        else
            # can be a file or a thumbnail
            mimeType = @model.get 'mime'
            mimeClass = @mimeClasses[mimeType]
            if mimeType? and mimeClass?
                iconType = mimeClass
            else
                iconType = 'type-file'
            if iconType == 'type-image'
                if renderData.model.binary && renderData.model.binary.thumb
                    iconType = 'type-thumb'
        @elementIcon.attr 'class', "icon-type #{iconType}"
        if iconType == 'type-thumb'
            @thumb.src = "files/photo/thumb/#{@model.id}"
        else
            @thumb.src = ''

        # show sharing status icon if necessary
        if @model.isShared()
            @elementIcon.addClass 'shared'
        else
            @elementIcon.removeClass 'shared'

        # update file link url
        @elementLink.attr 'href', link

        # update tags
        @tags.refresh(@model)

        # update name, size and type
        @elementName.html renderData.model.name
        @elementSize.html size
        @elementType.html t(type)

        # update last modification
        lastModification = renderData.model.lastModification
        if lastModification
            m = moment(lastModification)
            lastModification = m.calendar()
            longLastModification = m.format('lll')
        else
            lastModification = ''
            longLastModification = ''
        @elementLastModificationDate.html lastModification
        @elementLastModificationDate.attr 'title', longLastModification

        # link between the element and the model
        @$el.data 'cid', @model.cid

        if @model.isUploading() or @model.isServerUploading()
            @addProgressBar()
            @blockDownloadLink()
            @blockNameLink()
        else
            @removeProgressBar() if @progressbar?
            @$el.toggleClass 'broken', @model.isBroken()


        # When folders are drag and drop, they can be clicked before being
        # actually created, resulting in an error. Folders don't rely
        # on `isUploading` because it is needless, so they are treated
        # separately.
        if @model.isNew()
            @blockNameLink()

        # TODO : avoid or adapt to an update operation
        @hideLoading()
        @showLoading() if @hasUploadingChildren


    onUploadComplete: ->
        if @model.isFolder()
            @hasUploadingChildren = false
            @hideLoading()


    onCollectionChanged: ->
        if @model.isFolder()
            path = @model.getRepository()

            hasItems = @uploadQueue.getNumUploadingElementsByPath(path) > 0
            if hasItems and not @$('.spinholder').is ':visible'
                @showLoading()
            else if not hasItems and @$('.spinholder').is ':visible'
                @hideLoading()


    onSyncError: ->
        # For overwritten files, render entirely to show
        # modification date and type. Render folders unless they are in
        # an errored state.
        if @model.isConflict() or (@model.isFolder() and not @isErrored)
            @render()


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
        @tags.showInput()


    onDeleteClicked: ->
        new ModalView t('modal are you sure'), t('modal delete msg'), t('modal delete ok'), t('modal cancel'), (confirm) =>
            if confirm
                window.pendingOperations.deletion++
                @model.destroy
                    success: -> window.pendingOperations.deletion--
                    error: ->
                        window.pendingOperations.deletion--
                        ModalView.error t 'modal delete error'


    onEditClicked: (name) ->
        @el.displayMode = 'edit'
        @$el.addClass('edit-mode')
        width = @$('.caption').width() + 10
        model = @model.toJSON()
        model.class = 'folder' unless model.class?

        if typeof(name) is 'string'
            model.name = name

        # change the template
        clearance = @model.getClearance()
        iconClass = 'icon-type'
        if clearance == 'public' or (clearance && clearance.length > 0)
            iconClass += ' shared'
        if model.binary && model.binary.thumb
            iconClass += ' type-thumb'
            thumbSrc   = "files/photo/thumb/#{this.model.id}"
        else
            iconClass += ' ' + @mimeClasses[model.mime]
            thumbSrc   = ''

        @$el.html @templateEdit
            model     : model
            iconClass : iconClass
            thumbSrc  : thumbSrc
            clearance : clearance

        # manage input
        input = @$('.file-edit-name')[0]
        if name is ''
            input.placeholder = t 'new folder'
        @$('.file-edit-name').width width
        @$('.file-edit-name').focus()

        # manage selection in the input :
        # we only want to select the part before the file extension
        lastIndexOfDot = model.name.lastIndexOf '.'
        lastIndexOfDot = model.name.length if lastIndexOfDot is -1

        if typeof input.selectionStart isnt 'undefined'
            input.selectionStart = 0
            input.selectionEnd = lastIndexOfDot
        else if document.selection and document.selection.createRange
            # IE Branch...
            input.select()
            range = document.selection.createRange()
            range.collapse true
            range.moveStart 'character', 0
            range.moveEnd 'character', lastIndexOfDot
            range.select()



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
            @displayError t('modal error empty name')


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


    # when a file link (icon or name) is clicked, choose the action to lauch
    onFileLinkClicked: (e)=>
        # if an image, launch the gallerie viewer, otherwise let the browser
        # open the link in a new window
        if @model.attributes.mime?.substr(0,5)=='image'
            # ctrl + click on an img => open in new window, nothing to do
            if e.ctrlKey
                return
            window.app.gallery.show(@model)
            e.preventDefault()


    # When a line is clicked, it should mark the item as selected, unless the
    # user clicked a button.
    onLineClicked: (event) ->
        # List of selectors that will prevent the selection if they, or one
        # of their children, have been clicked.
        forbiddenSelectors = [
            '.operations'
            '.tags'
            '.link-wrapper'
            'a.file-edit-save'
            'a.file-edit-cancel'
            'span.error'
            '.selector-wrapper'
        ]

        if @$el.hasClass('edit-mode')
            return

        t = event.target
        for sel in forbiddenSelectors
            if $(t).parents(sel).length != 0 or t.matches(sel)
                return

        isShiftPressed = event.shiftKey or false
        window.getSelection().removeAllRanges()
        @model.toggleViewSelected isShiftPressed



    onKeyPress: (e) =>
        if e.keyCode is 13 # ENTER key
            @onSaveClicked()
        else if e.keyCode is 27 # ESCAPE key
            @onCancelClicked()


    onSelectClicked: (event) ->
        isShiftPressed = event.shiftKey or false
        @model.toggleViewSelected isShiftPressed


    onToggleSelect: ->
        isViewSelected = @model.isViewSelected()
        @$el.toggleClass 'selected', isViewSelected

        if isViewSelected
            @$('.selector-wrapper i').removeClass 'fa-square-o'
            @$('.selector-wrapper i').addClass 'fa-check-square-o'
        else
            @$('.selector-wrapper i').removeClass 'fa-check-square-o'
            @$('.selector-wrapper i').addClass 'fa-square-o'


    # add and display progress bar.
    addProgressBar: ->
        console.log 'addProgressBar', @progressbar

        @removeProgressBar() if @progressbar?
        @$el.addClass 'uploading'
        @$('.type-column-cell').hide()
        @$('.date-column-cell').hide()

        @progressbar = new ProgressBar model: @model
        @cell = $ '<td colspan="2" class="progressbar-cell" role="gridcell"></td>'
        @cell.append @progressbar.render().$el
        @$('.size-column-cell').after @cell


    # remove progress bar.
    removeProgressBar: ->
        console.log 'removeProgressBar', @progressbar
        @$('.type-column-cell').show()
        @$('.date-column-cell').show()
        @$el.removeClass 'uploading'
        if @progressbar?
            @progressbar.destroy()
            @progressbar = null
            console.log  'destroyed?', @progressbar
        @cell.remove()


    # Make download link inactive.
    blockDownloadLink: ->
        @$('a.caption.btn').click (event) -> event.preventDefault()


    # Make name link inactive.
    blockNameLink: ->
        @$('.link-wrapper > a').click (event) -> event.preventDefault()


    # Show loading spinner.
    showLoading: ->
        @$('.link-wrapper .fa').addClass 'hidden'
        @$('.spinholder').css 'display', 'inline-block'


    # Hide loading spinner.
    hideLoading: ->
        @$('.link-wrapper .fa').removeClass 'hidden'
        @$('.spinholder').hide()


    # returns the class for the
    getIconClass: ->
        # Determine the icon based on element's type.
        if @model.isFolder()
            icon = "type-folder"
        else
            mimeType = @model.get 'mime'
            mimeClass = @mimeClasses[mimeType]
            if mimeType? and mimeClass?
                icon = mimeClass
            else
                icon = "type-file"
        return icon
