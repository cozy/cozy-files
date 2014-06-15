BaseView = require '../lib/base_view'
ModalView = require "./modal"
ModalShareView = require "./modal_share"
TagsView = require "./tags"

client = require "../helpers/client"

module.exports = class FileView extends BaseView

    className      : 'folder-row'
    tagName        : 'tr'
    templateNormal : require './templates/file'
    templateEdit   : require './templates/file_edit'
    templateSearch : require './templates/file_search'

    events:
        'click a.file-delete'      : 'onDeleteClicked'
        'click a.file-share'       : 'onShare'
        'click a.file-edit'        : 'onEditClicked'
        'click a.file-edit-save'   : 'onSaveClicked'
        'click a.file-edit-cancel' : 'render'
        'click a.file-move'        : 'onMoveClicked'
        'keydown input'            : 'onKeyPress'

    template: (args) ->
        if app.folderView.model.get("type") is "search"
            @templateSearch args
        else
            @templateNormal args

    initialize: ->
        @listenTo @model, 'change', @render

    onDeleteClicked: ->
        new ModalView t("modal are you sure"), t("modal delete msg"), t("modal delete ok"), t("modal cancel"), (confirm) =>
            if confirm
                @model.destroy
                    error: ->
                        ModalView.error t("modal delete error")

    onEditClicked: ->
        width = @$(".caption").width() + 10
        model = @model.toJSON()
        model.class = 'folder' unless model.class?
        @$el.html @templateEdit(model: model)
        @tags = new TagsView
            el: @$('.tags')
            model: @model
        @tags.render()
        @$(".file-edit-name").width(width)
        @$(".file-edit-name").focus()


        # we only want to select the part before the file extension
        lastIndexOfDot = model.name.lastIndexOf '.'
        lastIndexOfDot = model.name.length if lastIndexOfDot is -1
        input = @$(".file-edit-name")[0]
        if typeof input.selectionStart isnt "undefined"
            input.selectionStart = 0
            input.selectionEnd = lastIndexOfDot
        else if document.selection && document.selection.createRange
            # IE Branch...
            input.select()
            range = document.selection.createRange()
            range.collapse true
            range.moveEnd "character", lastIndexOfDot
            range.moveStart "character", 0
            range.select()

    onShare: -> new ModalShareView model: @model

    onSaveClicked: ->
        name = @$('.file-edit-name').val()

        if name and name isnt ""

            @model.save name: name,
                wait: true
                success: (data) =>
                    @render()
                error: (model, err) =>
                    console.log err
                    if err.status is 400
                        ModalView.error t("modal error in use")
                    else
                        ModalView.error t("modal error rename")
        else
            ModalView.error t("modal error empty name")


    # Display Move widget and handle move operation if user confirms.
    onMoveClicked: =>
        client.get 'folders/list', (err, paths) =>
            if err
                alert err
            else
                paths.push '/'

                moveForm = $ """
                <div class="move-widget">
                <span> #{t 'move element to'}: </span>
                <select class="move-select"></select>
                <button class="button btn move-btn">
                    #{t 'move'}
                </button>
                <button class="btn btn-link cancel-move-btn">
                    #{t 'cancel'}
                </button>
                </div>
                """
                for path in paths
                    if path isnt @model.get('path').substring 1
                        moveForm.find('select').append """
                        <option value="#{path}">#{path}</option>
                        """

                moveForm.find(".cancel-move-btn").click -> moveForm.remove()
                moveButton = moveForm.find(".move-btn")
                moveButton.click =>
                    path = $(".move-select").val().substring 1
                    moveButton.css 'color', 'transparent'
                    moveButton.spin 'tiny', color: 'white'
                    id = @model.get 'id'
                    @stopListening @model
                    @model.collection.socketListener.pause @model, null,
                        ignoreMySocketNotification: true

                    client.put "files/#{id}", path: path, (err) =>
                        if err
                            alert "An error occured while moving element #{@model.get 'name'}."
                            console.log err
                            moveButton.spin false
                        else
                            alert "Element #{@model.get 'name'} was successfully moved to #{path}."
                            @$el.fadeOut =>
                                @model.remove()

                        @model.collection.socketListener.resume @model, null,
                            ignoreMySocketNotification: true
                        @listenTo @model, 'change', @render
                @$el.find('td:first-child').append moveForm



    onKeyPress: (e) =>
        if e.keyCode is 13
            @onSaveClicked()
        else if e.keyCode is 27
            @render()

    afterRender: ->
        @tags = new TagsView
            el: @$('.tags')
            model: @model
        @tags.render()
