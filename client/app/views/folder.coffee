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
        'click a#button-new-folder' : 'prepareNewFolder'
        'click #new-folder-send'    : 'onAddFolder'
        'click #upload-file-send'   : 'onAddFile'
        'keyup input#search-box'    : 'onSeachKeyPress'
        'keyup input#inputName'     : 'onAddFolderEnter'

    initialize: (options) -> 
        @breadcrumbs = options.breadcrumbs
        @breadcrumbs.setRoot @model

        # add drag and drop support
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


    ###
        Display and re-render the contents of the folder
    ###
    changeActiveFolder: (folder) ->
        # save the model
        @model = folder

        # update breadcrumbs
        @breadcrumbs.push folder

        # add files view
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

                    error: (error) =>
                        console.log error
                        new ModalView t("modal error"), t("modal error get folders"), t("modal ok")
            error: (error) =>
                console.log error
                new ModalView t("modal error"), t("modal error get files"), t("modal ok")


    ###
        Upload/ new folder
    ###
    prepareNewFolder: ->
        setTimeout () =>
            @$("#inputName").focus()
        , 500

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
        console.log "creating folder #{folder}"

        if folder.validate()
            new ModalView t("modal error"), t("modal error empty name"), t("modal ok")
        else
            @filesList.addFolder folder
            # hide modal
            $('#dialog-new-folder').modal('hide')

    onAddFile: =>
        for attach in @$('#uploader')[0].files
            @filesList.addFile attach

    onDragAndDrop: (e) =>
        e.preventDefault()
        e.stopPropagation()
        console.log "Drag and drop"
        
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
    onSeachKeyPress: (e) =>
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
