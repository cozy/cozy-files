BaseView = require '../lib/base_view'
ModalView = require "./modal"

module.exports = class FileView extends BaseView

    className      : 'folder-row'
    tagName        : 'tr'
    templateNormal : require './templates/file'
    templateEdit   : require './templates/file_edit'
    templateSearch : require './templates/file_search'

    events:
        'click a.file-delete'      : 'onDeleteClicked'
        'click a.file-edit'        : 'onEditClicked'
        'click a.file-edit-save'   : 'onSaveClicked'
        'click a.file-edit-cancel' : 'render'
        'keydown input'            : 'onKeyPress'

    template: (args) ->
        if app.folderView.model.get("type") is "search"
            @templateSearch args
        else
            @templateNormal args

    initialize: ->
        @listenTo @model, 'change', @render

    onDeleteClicked: ->
        new ModalView "Are you sure ?", "Deleting cannot be undone", "Delete", "cancel", (confirm) =>
            if confirm
                @model.destroy
                    error: ->
                        new ModalView "Error", "Server error occured, file was not deleted", "OK"

    onEditClicked: ->
        width = @$(".caption").width() + 10
        @$el.html @templateEdit(model: @model.toJSON())
        @$(".file-edit-name").width(width)
        @$(".file-edit-name").focus()

    onSaveClicked: ->
        name = @$('.file-edit-name').val()

        if name and name != ""

            @model.save name: name,
                patch: true
                wait: true
                success: (data) =>
                    console.log "File name changed successfully"
                    @render()
                error: (model, err)=>
                    console.log err
                    if err.status is 400
                        new ModalView "Error", "Name already in use", "OK"
                    else
                        new ModalView "Error", "Name could not be changed", "OK"
        else
            new ModalView "Error", "The name can't be empty", "OK"

    onKeyPress: (e) =>
        if e.keyCode is 13
            @onSaveClicked()
