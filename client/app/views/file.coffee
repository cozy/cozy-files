BaseView = require '../lib/base_view'
ModalView = require "./modal"

module.exports = class FileView extends BaseView

    className: 'folder-row'
    tagName: 'tr'
    template: require './templates/file'
    templateEdit: require './templates/file_edit'

    events:
        'click a.file-delete': 'onDeleteClicked'
        'click a.file-edit': 'onEditClicked'
        'click a.file-edit-save': 'onSaveClicked'
        'click a.file-edit-cancel': 'render'

    initialize: ->
        @listenTo @model, 'change:id', @render

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

    onSaveClicked: ->
        name = @$('.file-edit-name').val()

        if name and name != ""

            @model.set("name", name)
            @model.save null,
                patch: true
                success: (data) =>
                    console.log "File name changes successfully"
                    @render()
                error: =>
                    console.log "error"
                    new ModalView "Error", "Name could not be changed", "OK"
        else
            new ModalView "Error", "The name can't be empty", "OK"
