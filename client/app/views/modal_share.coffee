BaseView = require '../lib/base_view'
ModalView = require "./modal"
client = require "../helpers/client"

module.exports = class ModalShareView extends BaseView

    template: require './templates/modal_share'

    events:
        "click #modal-dialog-share-send" : "send"

    initialize: (options) ->
        console.log options
        @url = options.url
        @model = options.model
        @render()
        @$('#modal-dialog').modal('show')

    send: ->
        input = @$('#modal-dialog-share-input').val()
        console.log input
        mails = input.replace(/\s+/g, ' ').replace(/\ /g, ',').replace(/\,+/g, ',').split(",")

        console.log mails

        client.post "fileshare/#{@model.id}/send", users: mails,
            success: (data) =>
                @$('#modal-dialog').modal('hide')
                setTimeout () =>
                    @destroy()
                , 1000
            error: (data) =>
                new ModalView t("modal error"), t("modal share error"), t("modal ok")



    render: ->
        @$el.append @template(url: @url)
        $("body").append @el
        @
