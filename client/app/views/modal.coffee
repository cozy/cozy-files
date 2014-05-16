BaseView = require '../lib/base_view'

module.exports = class ModalView extends BaseView

    id: "dialog-modal"
    className: "modal fade"
    attributes:
        'tab-index': -1
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
        @cb true if @cb
        @hide()
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
        @$el.modal 'show'

    hide: ->
        @$el.modal 'hide'

    render: ->
        @$el.append @template(title: @title, msg: @msg, yes: @yes, no: @no)
        $("body").append @$el
        @afterRender()
        @

module.exports.error = (code, cb) ->
    new ModalView t("modal error"), code, t("modal ok"), false, cb
