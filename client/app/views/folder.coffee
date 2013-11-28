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

    getRenderData: ->
        model: @model

    afterRender: ->
        super()

        # add breadcrumbs view
        @breadcrumbsView = new BreadcrumbsView @breadcrumbs
        @$("#crumbs").append @breadcrumbsView.render().$el

        # add drag and drop support
        prevent = (e) ->
            e.preventDefault()
            e.stopPropagation()
        #@$el.on "dragover", prevent
        #@$el.on "dragenter", prevent
        #@$el.on "drop", (e) =>
        #    @onDragAndDrop(e)

        

    ###
        Display and re-render the contents of the folder
    ###
    changeActiveFolder: (folder) ->
        # save the model
        @model = folder
        # update breadcrumbs
        @breadcrumbs.push folder
        # files
        @displayChildren()

    displayChildren: ->

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
                        @stopListening @filesCollection, "progress:done"
                        @filesCollection = new FileCollection folders.concat(files)
                        @listenTo @filesCollection, "progress:done", @hideUploadForm

                        # render the collection
                        @filesList = new FilesView @filesCollection, @model

                        
                        @$('#files').html @filesList.$el
                        @filesList.render()

                    error: (error) =>
                        console.log error
                        new ModalView "Error", "Error getting folders from server", "OK"
            error: (error) =>
                console.log error
                new ModalView "Error", "Error getting files from server", "OK"


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
            console.log "enter on add folder"
            @onAddFolder()

    onAddFolder: =>
        folder = new File
            name: @$('#inputName').val()
            path: @model.repository()
            type: "folder"
        console.log "creating folder #{folder}"

        if folder.validate()
            new ModalView "Error", "Folder name can't be empty", "OK"
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
        # show a status bar
        $("#dialog-upload-file").modal("show")
        # send file
        for attach in e.dataTransfer.files
            @filesList.addFile attach

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
            name: "Search '#{query}'"
            type: "search"

        search = new File data
        @changeActiveFolder search
