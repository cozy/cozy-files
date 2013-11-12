ViewCollection = require '../lib/view_collection'

FileView = require './file'
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
            if file.get("name") == attach.name
                found = true
        
        if not found
            fileAttributes = 
                name: attach.name
                path: @model.repository()
            file = new File fileAttributes
            file.file = attach
            @collection.add file
            @upload file
        else
            alert "Sorry, the file already exists"

    upload: (file) =>
        formdata = new FormData()
        formdata.append 'cid', file.cid
        formdata.append 'name', file.get 'name'
        formdata.append 'path', file.get 'path'
        formdata.append 'file', file.file
        Backbone.sync 'create', file,
            contentType: false
            data: formdata
            success: (data) =>
                file.set data

    addFolder: (folder) ->
        @collection.create folder,
            success: (data) =>
                #app.folders.add data
            error: (error) =>
                @collection.reset folder
                alert error.msg