BaseView = require '../lib/base_view'
FilesView = require './files'
BreadcrumbsView = require "./breadcrumbs"

File = require '../models/file'
FileCollection = require '../collections/files'


module.exports = class FolderView extends BaseView

    template: require './templates/folder'

    events: ->  
        'click #new-folder-send': 'onAddFolder'
        'click #upload-file-send': 'onAddFile'

    constructor: (@model, @breadcrumbs) ->
        super()
        @breadcrumbs.setRoot @model

    render: ->
        @beforeRender()
        @$el.html @template model:@model
        @afterRender()
        @

    afterRender: ->
        super()

        # add breadcrumbs view
        @breadcrumbsView = new BreadcrumbsView @breadcrumbs
        @$("#crumbs").append @breadcrumbsView.render().$el


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

                @model.findFolders
                    success: (folders) =>

                        # mark folders as folders
                        for folder in folders
                            folder.isFolder = true

                        # render the collection
                        @filesCollection = new FileCollection files.concat(folders)
                        @filesList = new FilesView @filesCollection, @model

                        
                        @$('#files').html @filesList.$el
                        @filesList.render()

                    error: (error) =>
                        console.log error
            error: (error) =>
                console.log error


    onAddFolder: =>
        folder =
            name: @$('#inputName').val()
            path: @model.repository()
            isFolder: true
        folder = new File folder
        err = folder.validate folder.attributes
        if err
            alert "The folder name is empty"
        else
            @filesList.addFolder folder.attributes
            # hide modal
            $('#dialog-new-folder').modal('hide')

    onAddFile: =>
        for attach in @$('#uploader')[0].files
            @filesList.addFile attach
        $('#dialog-upload-file').modal('hide')