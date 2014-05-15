BaseView = require '../lib/base_view'

module.exports = class ModalView extends BaseView

    template: require './templates/modal'
    value: 0

    events: ->
        "click #modal-dialog-no"  : "onNo"
        "click #modal-dialog-yes" : "onYes"

    constructor: (@title, @msg, @yes, @no, @cb, @hideOnYes) ->
        super()
        @hideOnYes = true unless @hideOnYes?

    initialize: ->
        @render()
        @show()

    onYes: ->
        @hide()
        @cb true if @cb
        setTimeout () =>
            @destroy()
        , 1000

    onNo: ->
        @cb false if @cb
        @hide() if @hideOnYes
        setTimeout () =>
            @destroy()
        , 1000

    show: ->
        @$('#modal-dialog').modal 'show'

    hide: ->
        @$('#modal-dialog').modal 'hide'

    render: ->
        @$el.append @template(title: @title, msg: @msg, yes: @yes, no: @no)
        $("body").append @$el
        @afterRender()
        @

module.exports.error = (code, cb) ->
    new ModalView t("modal error"), code, t("modal ok"), false, cb
