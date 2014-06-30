BaseView = require '../lib/base_view'
FilesView = require './files'
BreadcrumbsView = require "./breadcrumbs"
ModalUploadView = require './modal_upload'
ModalFolderView = require './modal_folder'
ModalShareView = require './modal_share'

File = require '../models/file'
FileCollection = require '../collections/files'

###
Handles the display logic for a folder.
Main entry point of the interface: handles breadcrumb, buttons and files list
###
module.exports = class FolderView extends BaseView

    el: 'body'

    template: require './templates/folder'

    events: ->
        'click #button-new-folder'     : 'onNewFolderClicked'
        'click #button-upload-new-file': 'onUploadNewFileClicked'
        'click #new-folder-send'       : 'onAddFolder'
        'click #cancel-new-folder'     : 'onCancelFolder'
        'click #cancel-new-file'       : 'onCancelFile'
        'click #share-state'           : 'onShareClicked'

        'dragstart #files' : 'onDragStart'
        'dragenter #files' : 'onDragEnter'
        'dragover #files'  : 'onDragEnter'
        'dragleave #files' : 'onDragLeave'
        'drop #files'      : 'onDrop'

        'keyup input#search-box'       : 'onSearchKeyPress'

    initialize: (options) ->
        super options
        @baseCollection = options.baseCollection
        @uploadQueue = options.uploadQueue

        # not empty only if a search has started
        @query = options.query

    destroy: ->
        @breadcrumbsView.destroy()
        @breadcrumbsView = null
        @filesList.destroy()
        @filesList = null

        super()

    getRenderData: ->
        model: @model.toJSON()
        query: @query

    afterRender: ->
        @uploadButton = @$ '#button-upload-new-file'

        # breadcrumb management
        @renderBreadcrumb()

        # files list management
        @renderFileList()

        # We make a reload after the view is displayed to update
        # the client without degrading UX
        @refreshData()

    renderBreadcrumb: ->
        @$('#crumbs').empty()
        @breadcrumbsView = new BreadcrumbsView collection: @model.breadcrumb
        @$("#crumbs").append @breadcrumbsView.render().$el

    renderFileList: ->
        @filesList = new FilesView
                model: @model
                collection: @collection
                isSearchMode: @model.get('type') is "search"

        @filesList.render()

    spin: (state = 'small') -> @$("#loading-indicator").spin state

    # Refresh folder's content and manage spinner
    refreshData: ->
        @spin()
        @baseCollection.getFolderContent @model, => @spin false

    ###
        Button handlers
    ###
    onUploadNewFileClicked: ->
        @modal = new ModalUploadView
            model: @model
            validator: @validateNewModel
            uploadQueue: @uploadQueue

    onNewFolderClicked: ->
        @modal = new ModalFolderView
            model: @model
            validator: @validateNewModel
            uploadQueue: @uploadQueue

    onShareClicked: -> new ModalShareView model: @model

    # REFACTORING: should be improved and moved somewhere else
    validateNewModel: (model) =>
        myChildren = model.get('path') is @model.getRepository()
        found = @filesList.collection.findWhere name: model.get 'name'
        if myChildren and found
            return t 'modal error file exists'
        else
            return null

    ###
        Drag and Drop to upload
    ###
    onDragStart: (e) ->
        e.preventDefault()
        e.stopPropagation()

    onDragEnter: (e) ->
        e.preventDefault()
        e.stopPropagation()
        @uploadButton.addClass 'btn-cozy-contrast'
        @$('#files-drop-zone').show()

    onDragLeave: (e) ->
        e.preventDefault()
        e.stopPropagation()
        @uploadButton.removeClass 'btn-cozy-contrast'
        @$('#files-drop-zone').hide()

    onDrop: (e) ->
        e.preventDefault()
        e.stopPropagation()

        filesToUpload = e.dataTransfer.files
        if filesToUpload.length > 0
            @modal = new ModalUploadView
                model: @model
                validator: @validateNewModel
                files: filesToUpload
                uploadQueue: @uploadQueue
        @uploadButton.removeClass 'btn-cozy-contrast'
        @$('#files-drop-zone').hide()

    ###
        Search
    ###
    onSearchKeyPress: (e) ->
        query = @$('input#search-box').val()

        if query isnt ''
            route = "#search/#{query}"
        else
            route = ''

        window.app.router.navigate route, true

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
