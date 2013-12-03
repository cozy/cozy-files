ViewCollection = require '../lib/view_collection'

FileView = require './file'
ProgressbarView = require "./progressbar"
ModalView = require "./modal"

File = require '../models/file'
FileCollection = require '../collections/files'

SocketListener = require '../helpers/socket'

module.exports = class FilesView extends ViewCollection

    template: require('./templates/files')
    itemview: FileView
    collectionEl: '#table-items-body'
    @views = {}

    initialize: (@collection, @model) ->
        super()
        @listenTo @collection, "sort", @render
        @listenTo @collection, "remove", @render
        @listenTo @collection, "add", @render
        @socket = new SocketListener()
        @socket.watch @collection
        
    addFile: (attach) =>
        found = @collection.findWhere(name: attach.name)
        
        if not found
            fileAttributes = 
                name: attach.name
                path: @model.repository()
                type: "file"
            file = new File fileAttributes
            file.file = attach

            # add a progress bar
            progress = new ProgressbarView file
            $("#dialog-upload-file .modal-body").append progress.render().el

            @upload file
        else
            new ModalView "Error", "Sorry, could not upload the file #{attach.name}: it already exists", "OK"

    upload: (file) =>
        formdata = new FormData()
        formdata.append 'cid', file.cid
        formdata.append 'name', file.get 'name'
        formdata.append 'path', file.get 'path'
        formdata.append 'file', file.file
        file.save null,
            contentType: false
            data: formdata
            success: (data) =>
                console.log "File sent successfully"
                # file.set data
                @collection.add file, merge:true
                #new ModalView "Success", "File transfered successfully", "OK"
            error: =>
                console.log "error"
                new ModalView "Error", "File could not be sent to server", "OK"

    addFolder: (folder) ->
        found = @collection.findWhere(name: folder.get("name"))

        if not found
            folder.save null,
                success: (data) =>
                    console.log "Folder created successfully"
                    @collection.add folder
                error: (error) =>
                    console.log error
                    new ModalView "Error", "Folder could not be created", "OK"
        else
            new ModalView "Error", "Sorry, could not create the folder: it already exists", "OK"
