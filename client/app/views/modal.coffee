BaseView = require '../lib/base_view'

module.exports = class ModalView extends BaseView

    template: require './templates/modal'
    value: 0

    events:
        "click #modal-dialog-no": "onNo"
        "click #modal-dialog-yes": "onYes"

    constructor: (@title, @msg, @yes, @no, @cb) ->
        super()

    initialize: ->
        @render()
        @$('#modal-dialog').modal('show')

    onYes: ->
        @cb true if @cb
        @$('#modal-dialog').modal('hide')
        setTimeout () =>
            @destroy()
        , 1000

    onNo: ->
        @cb false if @cb
        @$('#modal-dialog').modal('hide')
        setTimeout () =>
            @destroy()
        , 1000

    render: ->
        @$el.append @template(title: @title, msg: @msg, yes: @yes, no: @no)
        $("body").append @el
        @
