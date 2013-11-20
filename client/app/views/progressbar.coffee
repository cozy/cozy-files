BaseView = require '../lib/base_view'

module.exports = class ProgressbarView extends BaseView

    className: 'progress'
    template: require './templates/progressbar'
    value: 0

    constructor: (@model) ->
        super()

    initialize: ->
        @listenTo @model, 'progress', @update

    update: (e) ->
        pc = parseInt(e.loaded / e.total * 100)
        console.log "[Progress bar] : #{pc} %"

        if pc == 100
            @model.trigger "progress:done"
            @remove()
            @destroy()
        else
            @value = pc
            @render()

    render: ->
        @$el.html @template(value: @value)
        @
