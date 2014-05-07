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
                        new ModalView t("modal error"), t("modal delete error"), t("modal ok")

    onEditClicked: ->
        width = @$(".caption").width() + 10
        model = @model.toJSON()
        model.class = 'folder' unless model.class?
        @$el.html @templateEdit(model: model)
        @tags = new TagsView
            el: @$('.tags')
            model: @model
        @$(".file-edit-name").width(width)
        @$(".file-edit-name").focus()

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
                        new ModalView t("modal error"), t("modal error in use"), t("modal ok")
                    else
                        new ModalView t("modal error"), t("modal error rename"), t("modal ok")
        else
            new ModalView t("modal error"), t("modal error empty name"), t("modal ok")

    onKeyPress: (e) =>
        if e.keyCode is 13
            @onSaveClicked()

    afterRender: ->
        @tags = new TagsView
            el: @$('.tags')
            model: @model
