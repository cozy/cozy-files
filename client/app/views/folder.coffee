BaseView = require '../lib/base_view'
FilesView = require './files'
BreadcrumbsView = require "./breadcrumbs"
ProgressbarView = require "./progressbar"
ModalUploadView = require './modal_upload'
ModalFolderView = require './modal_folder'
ModalShareView = require './modal_share'
ModalView = require './modal_share'
showError = require('./modal').error

File = require '../models/file'
FileCollection = require '../collections/files'



module.exports = class FolderView extends BaseView

    template: require './templates/folder'

    events: ->
        'click #button-new-folder'     : 'onNewFolderClicked'
        'click #button-upload-new-file': 'onUploadNewFileClicked'
        'click #new-folder-send'       : 'onAddFolder'
        'click #cancel-new-folder'     : 'onCancelFolder'
        'click #cancel-new-file'       : 'onCancelFile'
        'click #share-state'           : 'onShareClicked'

        'dragenter #button-upload-new-file' : 'onDragEnter'
        'dragover #button-upload-new-file'  : 'onDragEnter'
        'dragleave #button-upload-new-file' : 'onDragLeave'
        'drop #button-upload-new-file'      : 'onDrop'

        'keyup input#search-box'       : 'onSearchKeyPress'

    initialize: (options) ->
        @model = options.model
        @breadcrumbs = options.breadcrumbs
        @breadcrumbs.setRoot @model

    getRenderData: ->
        model: @model

    afterRender: ->
        @breadcrumbsView = new BreadcrumbsView @breadcrumbs
        @$("#crumbs").append @breadcrumbsView.render().$el
        @uploadButton = @$ '#button-upload-new-file'

        @filesList = new FilesView el: @$("#files"), model: @model
        @filesList.render()

    # Display and re-render the contents of the folder
    changeActiveFolder: (folder) ->
        # register the model
        @stopListening @model
        @model = folder
        @listenTo @model, 'change', -> @changeActiveFolder @model

        # update breadcrumbs
        @breadcrumbs.push folder
        if folder.id is "root"
            @$("#crumbs").css opacity: 0.5
        else
            @$("#crumbs").css opacity: 1

        # see, if we should display add/upload buttons
        if folder.get("type") is "folder"
            @$("#upload-buttons").show()
        else
            @$("#upload-buttons").hide()

        # manage share state button
        shareState = $ '#share-state'
        if @model.id isnt "root"
            shareState.show()
            clearance = @model.get 'clearance'
            if clearance is 'public'
                shareState.html "#{t('public')}&nbsp;"
                shareState.append $ '<span class="fa fa-globe"></span>'
            else if clearance and clearance.length > 0
                shareState.html "#{t('shared')}&nbsp;"
                shareState.append $ "<span class='fa fa-users'>" \
                                    + "</span>"
                shareState.append $ "<span>&nbsp;#{clearance.length}</span>"
            else
                shareState.html "#{t('private')}&nbsp;"
                shareState.append $ '<span class="fa fa-lock"></span>'
        else
            shareState.hide()

        # folder 'download zip' link
        zipLink = "folders/#{@model.get('id')}/zip/#{@model.get('name')}"
        @$('#download-link').attr 'href', zipLink

        @$("#loading-indicator").spin 'small'
        @model.findContent
            success: (content) =>
                for item in content
                    if item.docType.toLowerCase() is "file"
                        item.type = "file"
                    else
                        item.type = "folder"

                @stopListening @filesList.collection
                @filesList.collection.reset content
                @filesList.model = @model
                @listenTo @filesList.collection, "sync", @hideUploadForm
                @$("#loading-indicator").spin false

            error: (error) =>
                folderName = @model.get 'name'
                ModalView.error t("modal error get content", {folderName})
                @$("#loading-indicator").spin false

    onUploadNewFileClicked: ->
        @modal = new ModalUploadView
            model: @model
            validator: @validateNewModel

    onNewFolderClicked: ->
        @modal = new ModalFolderView
            model: @model
            validator: @validateNewModel

    validateNewModel: (model) =>
        myChildren = model.get('path') is @model.repository()
        found = @filesList.collection.findWhere name: model.get 'name'
        if myChildren and found
            return t 'modal error file exists'
        else
            return null

    ###
        Drag and Drop to upload
    ###
    onDragEnter: (e) ->
        e.preventDefault()
        e.stopPropagation()
        @uploadButton.addClass 'btn-cozy-contrast'

    onDragLeave: (e) ->
        e.preventDefault()
        e.stopPropagation()
        @uploadButton.removeClass 'btn-cozy-contrast'

    onDrop: (e) ->
        e.preventDefault()
        e.stopPropagation()

        filesToUpload = e.dataTransfer.files
        if filesToUpload.length > 0
            @modal = new ModalUploadView
                model: @model
                validator: @validateNewModel
                files: filesToUpload
        @uploadButton.removeClass 'btn-cozy-contrast'

    ###
        Search
    ###
    onSearchKeyPress: (e) =>
        query = @$('input#search-box').val()

        #if e.keyCode is 13
        if query isnt ""
            @displaySearchResults query
            app.router.navigate "search/#{query}"
        else
            @changeActiveFolder @breadcrumbs.root

    displaySearchResults: (query) ->
        @breadcrumbs.popAll()

        data =
            id: query
            name: "#{t('breadcrumbs search title')} '#{query}'"
            type: "search"

        search = new File data
        @changeActiveFolder search

    onShareClicked: ->
        new ModalShareView model: @model
