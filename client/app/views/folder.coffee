BaseView = require '../lib/base_view'
FilesView = require './files'
BreadcrumbsView = require "./breadcrumbs"
UploadStatusView = require './upload_status'
Modal = require './modal'
ModalBulkMove = require './modal_bulk_move'
ModalConflict = require './modal_conflict'
ModalShareView = null

File = require '../models/file'

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

        'change #select-all': 'onSelectAllChanged'
        'change input.selector': 'onSelectChanged'

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
        @listenTo @baseCollection, 'remove', @toggleFolderActions
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

        return this

    resolveConflict: (model, done) ->

        # if the user has selected the remember choice option
        # it is not asked again
        if @conflictRememberedChoice?
            model.overwrite = @conflictRememberedChoice
            model.processSave model
            done()
        else
            # Ask the user his choice about overwriting the file
            new ModalConflict model, (choice, rememberChoice) =>

                # save the remembered choice if the user has set it
                if rememberChoice?
                    @conflictRememberedChoice = rememberChoice

                model.overwrite = choice
                # starts the upload (and therefore unlocks the upload queue)
                model.processSave model

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
            isSearchMode: @model.get('type') is "search"

        @filesList.render()

    renderUploadStatus: ->
        @uploadStatus = new UploadStatusView
            collection: @uploadQueue

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
            @newFolder.type = 'folder'

            @baseCollection.add @newFolder
            view = @filesList.views[@newFolder.cid]
            view.onEditClicked()

            @newFolder.once 'sync destroy', => @newFolder = null

    onShareClicked: -> new ModalShareView model: @model

    ###
        Drag and Drop and Upload
    ###
    onDragStart: (e) ->
        e.preventDefault()
        e.stopPropagation()

    onDragEnter: (e) ->
        e.preventDefault()
        e.stopPropagation()
        if not @isPublic or @canUpload
            @uploadButton.addClass 'btn-cozy-contrast'
            @$('#files-drop-zone').show()

    onDragLeave: (e) ->
        e.preventDefault()
        e.stopPropagation()
        if not @isPublic or @canUpload
            @uploadButton.removeClass 'btn-cozy-contrast'
            @$('#files-drop-zone').hide()

    onDrop: (e) ->
        e.preventDefault()
        e.stopPropagation()
        return false if @isPublic and not @canUpload

        # folder drag and drop is only supported in Chrome
        if e.dataTransfer.items?
            @onFilesSelectedInChrome e
        else
            @onFilesSelected e

        @uploadButton.removeClass 'btn-cozy-contrast'
        @$('#files-drop-zone').hide()

    onDirectorySelected: (e) ->
        input = @$ '#folder-uploader'
        files = input[0].files
        return unless files.length
        @uploadQueue.addFolderBlobs files, @model
        # reset the input
        input.replaceWith input.clone true

    onFilesSelected: (e) =>
        files = e.dataTransfer?.files or e.target.files
        return unless files.length

        @uploadQueue.addBlobs files, @model

        if e.target?
            target = $ e.target
            # reset the input
            target.replaceWith target.clone true

    onFilesSelectedInChrome: (e) ->
        items = e.dataTransfer.items
        return unless items.length

        # Due to the asynchronous nature of the API, we use a pending system
        # where we increment and decrement it for each operations, only calling
        # the callback when there are no operation pending
        pending = 0
        files = []
        errors = []
        callback = =>

            processUpload = =>
                @uploadQueue.addFolderBlobs files, @model

                if e.target?
                    target = $ e.target
                    # reset the input
                    target.replaceWith target.clone true

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


        # An entry can be a folder or a file
        parseEntriesRecursively = (entry, path) =>
            pending = pending + 1
            path = path or ""
            path = "#{path}/" if path.length > 0

            # if it's a file we add it to the file list with a proper
            # relative path
            if entry.isFile
                entry.file (file) ->
                    file.relativePath = "#{path}#{file.name}"
                    files.push file
                    pending = pending - 1
                    # if there are no operation left, the upload starts
                    callback() if pending is 0
                , (error) ->
                    errors.push entry.name
                    pending = pending - 1
                    # if there are no operation left, the upload starts
                    callback() if pending is 0

            # if it's a directory, recursively call the function to reach
            # the leaves of the file tree
            else if entry.isDirectory
                reader = entry.createReader()
                reader.readEntries (entries) ->
                    for subEntry in entries
                        parseEntriesRecursively subEntry, "#{path}#{entry.name}"
                    pending = pending - 1

        # starts the parsing process
        for item in items
            entry = item.webkitGetAsEntry()
            parseEntriesRecursively entry


    ###
        Search
    ###
    onSearchKeyPress: (e) ->
        if @searching isnt true
            searching = true
            setTimeout =>
                query = @$('input#search-box').val()

                if query isnt ''
                    route = "#search/#{query}"
                else
                    route = ''

                window.app.router.navigate route, true
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
        isChecked = $(event.target).is ':checked'
        @$('input.selector').prop 'checked', isChecked
        @collection.forEach (element) ->
            element.isSelected = isChecked
            element.trigger 'toggle-select'

        @toggleFolderActions isChecked

    onSelectChanged: -> @toggleFolderActions()

    # Gets the number of selected elements from the collection
    getSelectedElements: ->
        return @collection.filter (element) -> return element.isSelected

    # we don't show the same actions wether there are selected elements or not
    toggleFolderActions: (force = false) ->
        selectedElements = @getSelectedElements()

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
        shouldChecked = \
            selectedElements.length is @collection.size() or force is true
        @$('input#select-all').prop 'checked', shouldChecked


    ###
        Bulk actions management
    ###
    bulkRemove: ->
        new Modal t("modal are you sure"), t("modal delete msg"), t("modal delete ok"), t("modal cancel"), (confirm) =>
            if confirm
                window.pendingOperations.deletion++
                async.eachSeries @getSelectedElements(), (element, cb) ->
                    element.destroy
                        success: -> setTimeout cb, 200
                        error: -> setTimeout cb, 200
                , (err) ->
                    window.pendingOperations.deletion--
                    if err?
                        Modal.error t("modal delete error")
                        console.log err

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
                <span class="text">#{t 'public'}</span>
                <span class="fa fa-globe"></span>
            """
        else if clearance? and clearance.length > 0
            shareStateContent = """
                <span class="text">#{t 'shared'}</span>
                <span class="fa fa-users"></span>
                <span>#{clearance.length}</span>
            """
        else
            shareStateContent = """
                <span class="text">#{t 'private'}</span>
                <span class="fa fa-lock"></span>
            """

        @$('#folder-state').html shareStateContent
