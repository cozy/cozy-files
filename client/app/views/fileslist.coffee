# This is where we import required modules
BaseView = require '../lib/base_view'
FileView  = require './fileslist_item'
# This is where we import required modules
BaseView = require '../lib/base_view'
FileView = require './fileslist_item'
File = require '../models/file'
ViewCollection = require '../lib/view_collection'

module.exports = class FilesListView extends ViewCollection

    template: require('./templates/fileslist')
    itemview: FileView
    collectionEl: '#file-list'
    @views = {}

    initialize: (data) ->
        super
        @repository = data.repository

    afterRender: ->
        super()
        
    addFile: (attach)=>
        fileAttributes = 
            name: attach.name
            path: @repository
        file = new File fileAttributes
        file.file = attach
        @collection.add file
        @upload file

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