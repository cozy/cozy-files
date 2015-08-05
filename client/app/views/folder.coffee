BaseView = require '../lib/base_view'
FilesView = require './files'
BreadcrumbsView = require "./breadcrumbs"
UploadStatusView = require './upload_status'
Modal = require './modal'
ModalBulkMove = require './modal_bulk_move'
ModalConflict = require './modal_conflict'
ModalShareView = null

File = require '../models/file'

BACKSPACE_KEY = 8

###
Handles the display logic for a folder.
Main entry point of the interface: handles breadcrumb, buttons and files list
###
module.exports = class FolderView extends BaseView

    el: 'body'

    template: require './templates/folder'

    events: ->
        'click #button-new-folder': 'onNewFolderClicked'
        'click #cancel-new-folder': 'onCancelFolder'
        'click #cancel-new-file': 'onCancelFile'
        'click #share-state': 'onShareClicked'
        'click #download-link': 'onDownloadAsZipClicked'
        'change #uploader': 'onFilesSelected'
        'change #folder-uploader': 'onDirectorySelected'

        'click #select-all': 'onSelectAllChanged'

        'click #button-bulk-download': 'bulkDownload'
        'click #button-bulk-remove': 'bulkRemove'
        'click #button-bulk-move': 'bulkMove'

        'dragstart #files': 'onDragStart'
        'dragenter #files': 'onDragEnter'
        'dragover #files': 'onDragEnter'
        'dragleave #files': 'onDragLeave'
        'drop #files': 'onDrop'

        'keyup input#search-box': 'onSearchKeyPress'

    initialize: (options) ->
        super options
        @baseCollection = options.baseCollection
        @uploadQueue = options.uploadQueue

        # not empty only if a search has started
        @query = options.query

        # prevent contacts loading in shared area
        unless app.isPublic
            ModalShareView ?= require "./modal_share"

        # refresh folder action buttons after bulk actions
        @listenTo @baseCollection, 'toggle-select', @toggleFolderActions
        @listenTo @collection, 'remove', @toggleFolderActions

        # when clearance is saved, we update the share button's icon
        @listenTo @model, 'sync', @onFolderSync

        # We create a queue to manage conflict, that process one item at a time
        # so we can use a remembered choice
        @conflictQueue = async.queue @resolveConflict.bind(@), 1
        @conflictRememberedChoice = null

        # reset remembered choice when all conflicts have been resolved
        @conflictQueue.drain = => @conflictRememberedChoice = null

        # adding the model to the queue when a conflict is detected by the
        # upload queue
        @listenTo @uploadQueue, 'conflict', @conflictQueue.push
        @listenTo @uploadQueue, 'folderError', @onMozFolderError
        @listenTo @uploadQueue, 'existingFolderError', @onExistingFolderError

        return this

    resolveConflict: (model, done) ->

        # if the user has selected the remember choice option
        # it is not asked again
        if @conflictRememberedChoice?
            model.solveConflict @conflictRememberedChoice
            done()
        else
            # Ask the user his choice about overwriting the file
            new ModalConflict model, (choice, rememberChoice) =>

                # save the remembered choice if the user has set it
                if rememberChoice?
                    @conflictRememberedChoice = rememberChoice

                model.solveConflict choice

                done()

    destroy: ->
        # reset selection for each models
        @collection.forEach (element) -> element.isSelected = false

        # properly destroy subviews
        @breadcrumbsView.destroy()
        @breadcrumbsView = null
        @filesList.destroy()
        @filesList = null

        # terminates conflict queue
        @conflictQueue.kill()
        @conflictQueue = null

        super()

    getRenderData: ->
        supportsDirectoryUpload: @testEnableDirectoryUpload()
        model: @model.toJSON()
        clearance: @model.getClearance()
        query: @query
        zipUrl: @model.getZipURL()


    afterRender: ->
        @uploadButton = @$ '#button-upload-new-file'

        # breadcrumb management
        @renderBreadcrumb()

        # files list management
        @renderFileList()

        # upload status management
        @renderUploadStatus()

        # We make a reload after the view is displayed to update
        # the client without degrading UX
        @refreshData()
        @$("#loading-indicator").show()
        @$('input#search-box').focus()

    renderBreadcrumb: ->
        @$('#crumbs').empty()
        @breadcrumbsView = new BreadcrumbsView
            collection: @model.breadcrumb
            model: @model
        @$("#crumbs").append @breadcrumbsView.render().$el

    renderFileList: ->

        @filesList = new FilesView
            model: @model
            collection: @collection
            uploadQueue: @uploadQueue
            numSelectedElements: @getSelectedElements().length
            isSearchMode: @model.get('type') is "search"

        @filesList.render()

    renderUploadStatus: ->
        @uploadStatus = new UploadStatusView
            collection: @uploadQueue.uploadCollection
            uploadQueue: @uploadQueue

        @uploadStatus.render().$el.appendTo @$('#upload-status-container')

    spin: (state=true) ->
        if state
            @$("#loading-indicator").show()
        else
            @$("#loading-indicator").hide()

    # Refresh folder's content and manage spinner
    refreshData: ->
        @spin()
        @baseCollection.getFolderContent @model, =>
            @spin false

            # if the inherited clearance has changed, we need to refresh
            # the share button's icon
            @onFolderSync()

    ###
        Button handlers
    ###

    onNewFolderClicked: ->

        if @newFolder
            # there is already a new folder
            @filesList.views[@newFolder.cid].$('.file-edit-name').focus()
        else
            @newFolder ?= new File
                name: ''
                type: 'folder'
                path: @model.getRepository()

            @baseCollection.add @newFolder
            view = @filesList.views[@newFolder.cid]
            view.onEditClicked t "new folder"

            @newFolder.once 'sync destroy', => @newFolder = null

    onShareClicked: ->
        new ModalShareView
            model: @model

    ###
        Drag and Drop and Upload
    ###
    onDragStart: (event) ->
        event.preventDefault()
        event.stopPropagation()

    onDragEnter: (event) ->
        event.preventDefault()
        event.stopPropagation()
        if not @isPublic or @canUpload
            @uploadButton.addClass 'btn-cozy-contrast'
            @$('#files-drop-zone').show()

    onDragLeave: (event) ->
        event.preventDefault()
        event.stopPropagation()
        if not @isPublic or @canUpload
            @uploadButton.removeClass 'btn-cozy-contrast'
            @$('#files-drop-zone').hide()

    onDrop: (event) ->
        event.preventDefault()
        event.stopPropagation()
        return false if @isPublic and not @canUpload

        # folder drag and drop is only supported in Chrome
        if event.dataTransfer.items?
            @onFilesSelectedInChrome event
        else
            @onFilesSelected event

        @uploadButton.removeClass 'btn-cozy-contrast'
        @$('#files-drop-zone').hide()

    onDirectorySelected: (event) ->
        input = @$ '#folder-uploader'
        files = input[0].files
        return unless files.length
        @uploadQueue.addFolderBlobs files, @model
        # reset the input
        input.replaceWith input.clone true

    onFilesSelected: (event) =>
        files = event.dataTransfer?.files or event.target.files

        if files.length
            @uploadQueue.addBlobs files, @model

            if event.target?
                target = $ event.target
                # reset the input
                target.replaceWith target.clone true

    onFilesSelectedInChrome: (e) ->
        items = e.dataTransfer.items
        return unless items.length

        files = []
        errors = []

        # Once all entries have been parsed, they are added to the upload queue.
        addAllToQueue = =>

            processUpload = =>
                @uploadQueue.addFolderBlobs files, @model

            if errors.length > 0
                formattedErrors = errors
                    .map (name) -> "\"#{name}\""
                    .join ', '
                localeOptions =
                    files: formattedErrors
                    smart_count: errors.length

                new Modal t('chrome error dragdrop title'), \
                    t('chrome error dragdrop content', localeOptions), \
                    t('chrome error submit'), null, (confirm) =>
                        processUpload()
            else
                processUpload()


        # An entry can be a folder or a file.
        parseEntriesRecursively = (entry, path, done) =>
            path = path or ""
            path = "#{path}/" if path.length > 0

            # If it's a file we add it to the file list with a proper
            # relative path.
            if entry.isFile
                entry.file (file) ->
                    file.relativePath = "#{path}#{file.name}"
                    files.push file
                    done()
                , (error) ->
                    errors.push entry.name
                    done()

            # If it's a directory, recursively call the function to reach
            # the leaves of the file tree.
            else if entry.isDirectory
                reader = entry.createReader()

                # .readEntries only return chunks of 100 elements, so it must
                # be called multiple times, until there is no more entries.
                do unshiftFolder = ->
                    reader.readEntries (entries) ->
                        if entries.length is 0
                            done()
                        else
                            async.eachSeries entries, (subEntry, next) ->
                                parseEntriesRecursively subEntry, "#{path}#{entry.name}", next
                            , unshiftFolder

        # Start the parsing process.
        async.eachSeries items, (item, next) ->
            entry = item.webkitGetAsEntry()
            parseEntriesRecursively entry, null, next
        , addAllToQueue


    ###
        Search
    ###
    onSearchKeyPress: (e) ->
        if @searching isnt true
            searching = true
            setTimeout =>
                query = @$('input#search-box').val().trim()

                if query isnt ''
                    route = "#search/#{query}"

                # query is empty and backspace is pressed = returns to home
                else if e.keyCode is BACKSPACE_KEY
                    route = ''

                # nothing should be done
                else
                    route = null

                window.app.router.navigate route, true if route?
                searching = false
            , 1000

    # Refreshes the view by changing the files list
    # we basically re-do @initialize but only render file list
    # to prevent the focus loss in the search field
    updateSearch: (model, collection) ->
        @stopListening @model
        @stopListening @collection
        @model = model
        @collection = collection

        $('#upload-buttons').hide()

        # the first time the view is displayed, it doesn't exist yet
        if @filesList?
            @filesList.destroy()
            # because destroying the view also removes the element
            @$('#loading-indicator').after $ '<div id="files"></div>'
        @renderBreadcrumb()
        @renderFileList()


    ###
        Select elements management
    ###
    onSelectAllChanged: (event) ->
        isChecked = @getSelectedElements().length is @collection.size()
        @collection.forEach (model) ->
            model.setSelectedViewState not isChecked


    # Gets the number of selected elements from the collection
    getSelectedElements: ->
        return @collection.filter (model) -> return model.isViewSelected()


    # we don't show the same actions wether there are selected elements or not
    toggleFolderActions: (event) ->
        {isShiftPressed} = event

        selectedElements = @getSelectedElements()

        # If shift key is hold, the user wants to select multiple elements in
        # one click.
        if isShiftPressed
            @handleSelectWithShift()

        if selectedElements.length > 0
            @$('#share-state').hide()
            @$('#upload-btngroup').hide()
            @$('#button-new-folder').hide()
            @$('#download-link').hide() # in public area
            @$('#bulk-actions-btngroup').addClass 'enabled'
        else
            if app.isPublic
                @$('#download-link').show() # in public area
                clearance = @model.getClearance()?[0]
                if clearance? and clearance.perm is 'rw'
                    @$('#upload-btngroup').show()
                    @$('#button-new-folder').show()
            else
                @$('#share-state').show()
                @$('#upload-btngroup').show()
                @$('#button-new-folder').show()
            @$('#bulk-actions-btngroup').removeClass 'enabled'


        # Check if all checkbox should be selected. It is selected
        # when it's forced or when collection length == amount of selected
        # files
        if selectedElements.length is 0 or @collection.size() is 0
            @$('#select-all i').removeClass 'fa-minus-square-o'
            @$('#select-all i').removeClass 'fa-check-square-o'
            @$('#select-all i').addClass 'fa-square-o'
        else if selectedElements.length is @collection.size()
            @$('#select-all i').removeClass 'fa-square-o'
            @$('#select-all i').removeClass 'fa-minus-square-o'
            @$('#select-all i').addClass 'fa-check-square-o'
        else
            @$('#select-all i').removeClass 'fa-square-o'
            @$('#select-all i').removeClass 'fa-check-square-o'
            @$('#select-all i').addClass 'fa-minus-square-o'


    # Handle the selection of multiple items within a range.
    handleSelectWithShift: ->
        selectedElements = @getSelectedElements()

        # There must be at least two items to be able to select items between
        # them.
        if selectedElements.length >= 2

            # Define the range within items will be selected.
            firstSelected = selectedElements[0]
            lastSelected = selectedElements[selectedElements.length - 1]
            firstSelectedIndex = @collection.indexOf firstSelected
            lastSelectedIndex = @collection.indexOf lastSelected

            @collection
                # Get the items to select.
                .filter (model, index) ->
                    return firstSelectedIndex < index < lastSelectedIndex and
                           not model.isViewSelected()

                # Select them.
                .forEach (model) -> model.toggleViewSelected()


    ###
        Bulk actions management
    ###
    bulkRemove: ->
        # TODO : add the confirmation modal (commented for ease of tests)
        # new Modal t("modal are you sure"), t("modal delete msg"), t("modal delete ok"), t("modal cancel"), (confirm) =>
        #     if confirm
                selectedElements = @getSelectedElements()
                window.pendingOperations.deletion += selectedElements.length
                # we manage ourself the remove of all the models of the
                # collection instead of removing one by one after each
                # model.destroy of the sync serie
                for model in selectedElements
                    @collection.remove(model)
                # asynchronous destroy of the models
                async.filter(
                    selectedElements
                    , (model, cb) =>
                        model.destroy
                            success: (model,response) ->
                                # BIN À PRIORI RIEN À FAIRE ?
                                # setTimeout ()->
                                #     cb(model,response)
                                # , 200
                                window.pendingOperations.deletion--
                                cb(false)
                            error: (model) =>
                                # the deletion has not been done on the server
                                # we re-integrate the model in the collection
                                window.pendingOperations.deletion--
                                cb(true)
                                # increase the file counter ? géré par filesView ?
                            # we manage ourself the remove of all the models
                            # instead of removing one by one after each
                            # model.destroy of the sync serie
                            silent: false
                            wait  : false

                    , (undeletedModels) =>
                        if undeletedModels.length > 0
                            console.log "bulkRemove callback : #{undeletedModels.length} deletion(s) failed", undeletedModels
                            Modal.error undeletedModels.length + t("modal delete error")
                            sortedModelsInError = _.sortBy(
                                undeletedModels
                                , (model)-> return model.rank
                            )
                            for model in sortedModelsInError
                                @collection.add(model)
                )


    bulkMove: ->
        new ModalBulkMove
            collection: @getSelectedElements()
            parentPath: @model.getRepository()

    bulkDownload: ->
        selectedElements = @getSelectedElements()
        selectedPaths = selectedElements.map (element) ->
            if element.isFolder()
                return "#{element.getRepository()}/"
            else
                return "#{element.getRepository()}"
        url = @model.getZipURL()

        serializedSelection = selectedPaths.join ';'

        # To trigger a download from a POST request, we must create an hidden
        # form and submit it.
        inputValue = """
        value="#{serializedSelection}"
        """
        form = """
        <form id="temp-zip-download" action="#{url}" method="post">
            <input type="hidden" name="selectedPaths" #{inputValue}/>
        </form>
        """
        $('body').append form
        $('#temp-zip-download').submit()
        $('#temp-zip-download').remove()


    ###
        Misc
    ###
    testEnableDirectoryUpload: ->
        input = $('<input type="file">')[0]
        supportsDirectoryUpload = input.directory? or
                                  input.mozdirectory? or
                                  input.webkitdirectory? or
                                  input.msdirectory?
        return supportsDirectoryUpload

    # We don't want the user to download the ZIP if the folder is empty
    onDownloadAsZipClicked: (event) ->
        if @collection.length is 0
            event.preventDefault()
            Modal.error t 'modal error zip empty folder'

    # Updates the share button's icon and content
    onFolderSync: ->
        clearance = @model.getClearance()
        if clearance is 'public'
            shareStateContent = """
                <span class="fa fa-globe"></span>
                <span class="text">#{t 'shared'}</span>
            """
        else if clearance? and clearance.length > 0
            shareStateContent = """
                <span class="fa fa-globe"></span>
                <span class="text">#{t 'shared'}</span>
                <span>(#{clearance.length})</span>
            """
        else
            shareStateContent = ""

        @$('#folder-state').html shareStateContent
        @filesList.updateInheritedClearance [clearance: clearance]

    # Display an error when the user tries to upload a folder in Firefox.
    onMozFolderError: =>
        Modal.error t('modal error firefox dragdrop folder')


    # Display an error when the user tries to drag and drop an existing folder.
    onExistingFolderError: (model) ->
        Modal.error t('modal error existing folder', name: model.get('name'))


