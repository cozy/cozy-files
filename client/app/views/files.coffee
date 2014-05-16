BaseView = require '../lib/base_view'
ViewCollection = require '../lib/view_collection'

FileView = require './file'
FileCollection = require '../collections/files'
ProgressbarView = require "./progressbar"
ModalView = require "./modal"

File = require '../models/file'
FileCollection = require '../collections/files'

SocketListener = require '../helpers/socket'

class FileList extends ViewCollection
    itemview: FileView
    collectionEl: '#table-items-body'

    initialize: (options) ->
        @collection = options.collection
        @listenTo @collection, "sort", @render
        @listenTo @collection, "remove", @render
        @socket = new SocketListener()
        @socket.watch @collection
        @$collectionEl = options.$collectionEl
        super options


module.exports = class FilesView extends BaseView
    template: require './templates/files'
    id: 'files'
    el: '#files'

    events:
        'click #up-name'               : 'onChangeOrder'
        'click #down-name'             : 'onChangeOrder'
        'click #up-class'              : 'onChangeOrder'
        'click #down-class'            : 'onChangeOrder'
        'click #up-size'               : 'onChangeOrder'
        'click #down-size'             : 'onChangeOrder'
        'click #up-lastModification'   : 'onChangeOrder'
        'click #down-lastModification' : 'onChangeOrder'


    @views = {}

    initialize: (options) ->
        super options
        @model = options.model
        @firstRender = true
        @collection = new FileCollection
        @listenTo @collection, "reset", @updateNbFiles
        @listenTo @collection, "add", @updateNbFiles
        @listenTo @collection, "remove", @updateNbFiles

    afterRender: ->
        super
        @fileList = new FileList
            collection: @collection
            $collectionEl: @$ '#table-items-body'

        @fileList.render()
        @$("#no-files-indicator").hide()
        @$("#file-amount-indicator").hide()
        @displayChevron 'up', 'name' if @firstRender

    updateNbFiles: ->
        nbFiles = 0

        for model in @collection.models
            if model.get('type') is 'file'
                nbFiles += 1

        if nbFiles > 0
            @$("#file-amount-indicator").show()
            @$("#no-files-indicator").hide()
            @$("#file-amount").html nbFiles
        else
            @$("#file-amount-indicator").hide()

            if @collection.models.length is 0
                @$("#no-files-indicator").show()
            else
                @$("#no-files-indicator").hide()

        @firstRender = false

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
        path = file.get 'path'
        path = '' if file.get('id') is 'root'
        formdata = new FormData()
        formdata.append 'cid', file.cid
        formdata.append 'name', file.get 'name'
        formdata.append 'path', path
        formdata.append 'file', file.file
        formdata.append 'lastModification', file.get 'lastModification'
        file.save null,
            contentType: false
            data: formdata
            success: (data) =>
                if not noDisplay
                    @collection.add file, merge: true
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

    # Helpers to display correct chevron to sort files
    displayChevron: (order, type) ->
        @$('#up-name').show()
        @$('#up-name').addClass 'unactive'
        @$('#down-name').hide()
        @$('#up-size').show()
        @$('#up-size').addClass 'unactive'
        @$('#down-size').hide()
        @$('#up-class').show()
        @$('#up-class').addClass 'unactive'
        @$('#down-class').hide()
        @$('#up-lastModification').show()
        @$('#up-lastModification').addClass 'unactive'
        @$('#down-lastModification').hide()

        if order is "down"
            @$("#up-#{type}").show()
            @$("#down-#{type}").hide()
            @$("#up-#{type}").removeClass 'unactive'
        else
            @$("#up-#{type}").hide()
            @$("#down-#{type}").show()
            @$("#down-#{type}").removeClass 'unactive'


    # Changer sorting depending on the clicked chevron.
    onChangeOrder: (event) ->
        infos = event.target.id.split '-'
        way = infos[0]
        type = infos[1]

        @displayChevron way, type
        @collection.type = type

        if @collection.order is "incr"
            @collection.order = "decr"
            @collection.sort()
        else
            @collection.order = "incr"
            @collection.sort()
