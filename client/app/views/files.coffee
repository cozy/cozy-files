ViewCollection = require '../lib/view_collection'

FileView = require './file'
ProgressbarView = require "./progressbar"
ModalView = require "./modal"

File = require '../models/file'
FileCollection = require '../collections/files'

module.exports = class FilesView extends ViewCollection

    template: require('./templates/files')
    itemview: FileView
    collectionEl: '#table-items-body'
    @views = {}

    initialize: (@collection, @model) ->
        super()
        @listenTo @collection, "sort", @render

    afterRender: ->
        super()
        
    addFile: (attach) =>
        found = false
        for file in @collection.models
            if (file.get("name") == attach.name) and file.get("type") is "file"
                found = true
        
        if not found
            fileAttributes = 
                name: attach.name
                path: @model.repository()
                type: "file"
            file = new File fileAttributes
            file.file = attach
            @collection.add file

            # add a progress bar
            progress = new ProgressbarView file
            $("#dialog-upload-file .modal-body").append progress.render().el

            @upload file
        else
            new ModalView "Error", "Sorry, could not upload the file: it already exists", "OK"

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
                file.set data
                #new ModalView "Success", "File transfered successfully", "OK"
            error: =>
                console.log "error"
                new ModalView "Error", "File could not be sent to server", "OK"

    addFolder: (folder) ->
        found = false
        for file in @collection.models
            if (file.get("name") == folder.get("name")) and file.get("type") is "folder"
                found = true

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
