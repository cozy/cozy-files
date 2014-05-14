BaseView = require '../lib/base_view'
FilesView = require './files'
BreadcrumbsView = require "./breadcrumbs"
ProgressbarView = require "./progressbar"
ModalView = require "./modal"
ModalFolderView = require './modal_folder'
ModalShareView = require './modal_share'
showError = require('./modal').error

File = require '../models/file'
FileCollection = require '../collections/files'



module.exports = class FolderView extends BaseView

    template: require './templates/folder'

    events: ->
        'click a#button-new-folder'    : 'prepareNewFolder'
        'click a#button-upload-new-file': 'onUploadNewFileClicked'
        'click #new-folder-send'       : 'onAddFolder'
        'click #cancel-new-folder'     : 'onCancelFolder'
        'click #upload-file-send'      : 'onAddFile'
        'click #cancel-new-file'       : 'onCancelFile'
        'click #share-state'           : 'onShareClicked'

        'click #up-name'               : 'onChangeOrder'
        'click #down-name'             : 'onChangeOrder'
        'click #up-class'              : 'onChangeOrder'
        'click #down-class'            : 'onChangeOrder'
        'click #up-size'               : 'onChangeOrder'
        'click #down-size'             : 'onChangeOrder'
        'click #up-lastModification'   : 'onChangeOrder'
        'click #down-lastModification' : 'onChangeOrder'

        'keyup input#search-box'       : 'onSearchKeyPress'
        'keyup input#inputName'        : 'onAddFolderEnter'

    initialize: (options) ->
        @model = options.model
        @breadcrumbs = options.breadcrumbs
        @breadcrumbs.setRoot @model

        @setDragNDrop()


    # Set Drag and drop properly.
    setDragNDrop: ->
        prevent = (e) ->
            e.preventDefault()
            e.stopPropagation()
        @$el.on "dragover", prevent
        @$el.on "dragenter", prevent
        @$el.on "drop", (e) =>
            @onDragAndDrop(e)

    getRenderData: ->
        model: @model

    afterRender: ->
        @breadcrumbsView = new BreadcrumbsView @breadcrumbs
        @$("#crumbs").append @breadcrumbsView.render().$el
        @displayChevron 'up', 'name'

        @modalFolder = new ModalFolderView
        @modalFolder.afterRender()
        @modalFolder.hide()


    # Helpers to display correct chevron to sort files
    displayChevron: (order, type) ->
        @$('#up-name').show()
        @$('#up-name').addClass 'unactive'
        @$('#down-name').hide()
        @$('#up-size').show()
        @$('#up-size').addClass 'unactive'
        @$('#down-size').hide()
        @$('#up-class').show()
        @$('#up-class').addClass 'unactive'
        @$('#down-class').hide()
        @$('#up-lastModification').show()
        @$('#up-lastModification').addClass 'unactive'
        @$('#down-lastModification').hide()

        if order is "down"
            @$("#up-#{type}").show()
            @$("#down-#{type}").hide()
            @$("#up-#{type}").removeClass 'unactive'
        else
            @$("#up-#{type}").hide()
            @$("#down-#{type}").show()
            @$("#down-#{type}").removeClass 'unactive'

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

        # add files view
        @filesList?.$el.html null
        #@$("#loading-indicator").spin 'small'
        @model.findFiles
            success: (files) =>

                # mark files as files
                for file in files
                    file.type = "file"

                @model.findFolders
                    success: (folders) =>

                        # mark folders as folders
                        for folder in folders
                            folder.type = "folder"

                        # new collection
                        if @filesCollection
                            @stopListening @filesCollection
                        @filesCollection = new FileCollection folders.concat(files)
                        @listenTo @filesCollection, "sync", @hideUploadForm

                        # render the collection
                        @filesList?.destroy() if @filesList
                        @filesList = new FilesView @filesCollection, @model
                        @$('#files').html @filesList.$el
                        @filesList.render()
                        @modalFolder.filesList = @filesList
                        #@$("#loading-indicator").spin()
                    error: (error) =>
                        console.log error
                        showError t "modal error get folders"
                        #@$("#loading-indicator").spin()
            error: (error) =>
                console.log error
                showError t "modal error get files"

    onUploadNewFileClicked: ->
        $("#dialog-upload-file .progress-name").remove()

    # Upload/ new folder
    prepareNewFolder: ->
        @modalFolder.showModal @model.get 'path'

    onCancelFolder: ->
        @$("#inputName").val("")



    onAddFile: =>
        for attach in @$('#uploader')[0].files
            @filesList.addFile attach
        @$('#uploader').val("")

    onCancelFile: ->
        @$("#uploader").val("")

    onDragAndDrop: (e) =>
        e.preventDefault()
        e.stopPropagation()

        # send file
        atLeastOne = false
        for attach in e.dataTransfer.files
            if attach.type is ""
                showError t "#{attach.name} #{t('modal error file invalid')}"
            else
                @filesList.addFile attach
                atLeastOne = true

        if atLeastOne
            # show a status bar
            $("#dialog-upload-file").modal("show")

    hideUploadForm: ->
        $('#dialog-upload-file').modal('hide')
        $('#dialog-new-folder').modal('hide')


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

    # Changer sorting depending on the clicked chevron.
    onChangeOrder: (event) ->
        infos = event.target.id.split '-'
        way = infos[0]
        type = infos[1]

        @displayChevron way, type
        @filesCollection.type = type

        if @filesCollection.order is "incr"
            @filesCollection.order = "decr"
            @filesCollection.sort()
        else
            @filesCollection.order = "incr"
            @filesCollection.sort()

    onShareClicked: ->
        new ModalShareView model: @model
