BaseView = require '../lib/base_view'
ModalView = require "./modal"
client = require "../helpers/client"

module.exports = class ModalShareView extends BaseView

    template: require './templates/modal_share_file'

    events:
        "click .yes-share": "onYesShareClicked"
        "click .no-share": "onNoShareClicked"
        "click #modal-dialog-share-send": "send"

    initialize: (options) ->
        @url      = options.url
        @model    = options.model

        if @model.get("type") is "folder"
            @template = require './templates/modal_share_folder'

        @render()
        @afterRender()

        @$('#modal-dialog').modal('show')

    onYesShareClicked: ->
        @model.set 'public', true
        @model.save public: true
        @afterRender()

    onNoShareClicked: ->
        @model.set 'public', false
        @model.save public: false
        @afterRender()

    # Show share options only if file or folder is public.
    afterRender: ->
        if @model.get 'public'
            @$(".share-infos").show()
            @$('#modal-dialog-share-send').removeClass('disabled')
            @$('.yes-share').addClass 'toggled'
            @$('.no-share').removeClass 'toggled'
        else
            @$(".share-infos").hide()
            @$('#modal-dialog-share-send').addClass('disabled')
            @$('.yes-share').removeClass 'toggled'
            @$('.no-share').addClass 'toggled'

    send: ->
        input = @$('#modal-dialog-share-input').val()
        mails = input.replace(/\s+/g, ' ').replace(/\ /g, ',').replace(/\,+/g, ',').split(",")

        client.post "#{@model.endpoint()}/#{@model.id}/send", users: mails,
            success: (data) =>
                @$('#modal-dialog').modal('hide')
                setTimeout () =>
                    @destroy()
                , 1000
            error: (data) =>
                new ModalView t("modal error"), t("modal share error"), t("modal ok")

    render: ->
        @$el.append @template(url: @url, model: @model)
        $("body").append @el
        @
