BaseView = require '../lib/base_view'
FilesView = require './files'
BreadcrumbsView = require "./breadcrumbs"
ProgressbarView = require "./progressbar"
ModalView = require "./modal"

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
        # add breadcrumbs view
        @breadcrumbsView = new BreadcrumbsView @breadcrumbs
        @$("#crumbs").append @breadcrumbsView.render().$el
        @displayChevron('up', 'name')


    # Helpers to display correct chevron to sort files
    displayChevron: (order, type) ->
        @$('#up-name').show()
        @$('#down-name').hide()
        @$('#up-size').show()
        @$('#down-size').hide()
        @$('#up-class').show()
        @$('#down-class').hide()
        @$('#up-lastModification').show()
        @$('#down-lastModification').hide()
        @$("##{order}-#{type}").show()
        if order is "up"
            @$("##{order}-#{type}")[0].removeAttribute('disabled')
        else
            @$("#up-#{type}").hide()

    # Display and re-render the contents of the folder
    changeActiveFolder: (folder) ->
        # register the model
        @model = folder

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


        # add files view

        @filesList?.$el.html null
        @$("#loading-indicator").spin 'small'
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
                        @$("#loading-indicator").spin()
                    error: (error) =>
                        console.log error
                        new ModalView t("modal error"), t("modal error get folders"), t("modal ok")
                        @$("#loading-indicator").spin()
            error: (error) =>
                console.log error
                new ModalView t("modal error"), t("modal error get files"), t("modal ok")

    onUploadNewFileClicked: ->
        $("#dialog-upload-file .progress-name").remove()
        $("#dialog-upload-file").modal("show")

    # Upload/ new folder
    prepareNewFolder: ->
        setTimeout () =>
            @$("#inputName").focus()
        , 500

    onCancelFolder: ->
        @$("#inputName").val("")


    onAddFolderEnter: (e) ->
        if e.keyCode is 13
            e.preventDefault()
            e.stopPropagation()
            @onAddFolder()

    onAddFolder: =>
        folder = new File
            name: @$('#inputName').val()
            path: @model.repository()
            type: "folder"
        @$("#inputName").val("")

        if folder.validate()
            new ModalView t("modal error"), t("modal error empty name"), t("modal ok")
        else
            @filesList.addFolder folder
            # hide modal
            $('#dialog-new-folder').modal('hide')

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
                new ModalView t("modal error"), "#{attach.name} #{t('modal error file invalid')}", t("modal ok")
            else
                @filesList.addFile attach
                atLeastOne = true

        if atLeastOne
            # show a status bar
            $("#dialog-upload-file").modal("show")

    hideUploadForm: ->
        $('#dialog-upload-file').modal('hide')


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

        @$(".glyphicon-chevron-up").addClass 'unactive'
        @$("#up-#{type}").removeClass 'unactive'
        @displayChevron way, type
        @filesCollection.type = type

        if @filesCollection.order is "incr"
            @filesCollection.order = "decr"
            @filesCollection.sort()
            @displayChevron 'down', @filesCollection.type
        else
            @filesCollection.order = "incr"
            @filesCollection.sort()
            @displayChevron 'up', @filesCollection.type