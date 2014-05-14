BaseView = require '../lib/base_view'
Modal = require "./modal"
Helpers = require '../lib/folder_helpers'
File = require '../models/file'
ModalView = require "./modal"

showError = require('./modal').error
Client = require "../helpers/client"

# extends the cozy-clearance modal to files specifics
module.exports = class ModalFolderView extends Modal

    id: "dialog-new-folder"
    className: "modal fade"
    attributes:
        'tab-index': -1
    template: require './templates/modal_folder'

    events:
        "click #new-folder-send" : "onYes"
        "keyup #inputName" : "onKeyUp"

    # - display upload folder form only if it is supported
    # - Register submit button
    afterRender: ->
        uploadDirectoryInput = @$("#folder-uploader")[0]
        supportsDirectoryUpload = uploadDirectoryInput.directory or
                                  uploadDirectoryInput.mozdirectory or
                                  uploadDirectoryInput.webkitdirectory or
                                  uploadDirectoryInput.msdirectory

        if supportsDirectoryUpload
            @$("#folder-upload-form").removeClass('hide')

        @submitButton = @$ "#new-folder-send"
        #@submitButton.css 'color', 'transparent'
        @submitButton.spin()
        @showModal()

    onKeyUp: (event) =>
        if event.keyCode is 13
            event.preventDefault()
            event.stopPropagation()
            @onYes()

    onYes: =>
        prefix = @prefix

        folder = new File
            name: @$('#inputName').val()
            path: prefix
            type: "folder"

        files = @$('#folder-uploader')[0].files

        if not files.length and folder.validate()
            showError t "modal error no data"
            return

        if not folder.validate()
            @submitButton.spin 'tiny'
            @filesList.addFolder folder, true, =>
                @submitButton.spin()
                @hide()

        if files.length
            # create the necessary (nested) folder structure
            dirsToCreate = Helpers.nestedDirs files

            createDir = ->
                if dirsToCreate.length > 0
                    dir = dirsToCreate.pop()
                    # figure out the name and path for the folder
                    dir = Helpers.removeTralingSlash dir
                    parts = dir.split '/'
                    path = "#{prefix}/#{parts[...-1].join '/'}"
                    path = Helpers.removeTralingSlash path
                    console.log path

                    nFolder = new File
                        name: parts[-1..][0]
                        path: path
                        type: "folder"

                    response = @filesList.addFolder nFolder, true, (err) =>
                        if err
                            showError err.txt
                            alert 'finished'
                            @hide()
                        else
                            createDir()
                else
                    alert 'finished'
                    @hide()

            # now that the required folder structure was created, upload files
            # filter out . and ..
            #files = (file for file in files when (file.name isnt "." and file.name isnt ".."))
            #for file in files
                #relPath = file.relativePath or
                          #file.mozRelativePath or
                          #file.webkitRelativePath or
                          #file.msRelativePath
                #file.path = "#{prefix}/#{Helpers.dirName relPath }"
                #response = @filesList.addFile file, true

                ## stop if the file already exists
                #return if response instanceof ModalView

    # Clean everythin before showing modal. Once displayed, focus the input.
    showModal: (prefix) ->
        $("#dialog-new-folder .progress-name").remove()
        @$("#inputName").val ""
        @prefix = prefix
        @$el.modal 'show'
        setTimeout ->
            @$("#inputName").focus()
        , 500
