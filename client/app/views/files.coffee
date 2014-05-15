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

    addFile: (attach, dirUpload) =>
        found = @collection.findWhere name: attach.name

        if not found
            fileAttributes =
                'name'               : attach.name
                'path'               : attach.path or @model.repository()
                'type'               : "file"
                'lastModification'   : attach.lastModifiedDate

            file = new File fileAttributes
            file.file = attach

            # add a progress bar
            progress = new ProgressbarView file
            if dirUpload
                dialogEl = "dialog-new-folder"
            else
                dialogEl = "dialog-upload-file"

            $("##{dialogEl} .modal-body").append(
               "<div class=\"progress-name\">#{attach.name}</div>"
            )
            $("##{dialogEl} .modal-body").append progress.render().el

            @upload file, dirUpload
        else
            ModalView.error "#{t('modal error file exists')}: #{attach.name}"

    upload: (file, noDisplay) =>
        formdata = new FormData()
        formdata.append 'cid', file.cid
        formdata.append 'name', file.get 'name'
        formdata.append 'path', file.get 'path'
        formdata.append 'file', file.file
        formdata.append 'lastModification', file.get 'lastModification'
        file.save null,
            contentType: false
            data: formdata
            success: (data) =>
                if not noDisplay
                    @collection.add file, merge:true
            error: =>
                ModalView.error t("modal error file upload")

    addFolder: (folder, noDisplay, callback) ->
        found = @collection.findWhere(name: folder.get("name"), path: folder.get("path"))

        if not found
            folder.save null,
                success: (data) =>
                    if not noDisplay
                        @collection.add folder
                    callback() if callback?
                error: (error) =>
                    error.txt = "modal error folder create"
                    callback error
        else
            error.txt = "modal error folder exists"
            callback error
