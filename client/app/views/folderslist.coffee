# This is where we import required modules
BaseView = require '../lib/base_view'
FileView  = require './fileslist_item'
# This is where we import required modules
BaseView = require '../lib/base_view'
FolderView = require './folderslist_item'
Folder = require '../models/folder'
ViewCollection = require '../lib/view_collection'
app = require 'application'

module.exports = class FilesListView extends ViewCollection

    template: require('./templates/folderslist')
    itemview: FolderView
    collectionEl: '#folder-list'
    @views = {}


    initialize: (data) ->
        super        
        @repository = ""
        if data.repository?
            @repository = data.repository

    afterRender: () ->
    	super
    	@name = @$('#name')

    onAddFolder: (folder) ->
        @collection.create folder,
            success: (data) =>
                app.folders.add data
            error: (error) =>
                @collection.reset folder
                alert error.msg