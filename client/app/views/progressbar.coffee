BaseView = require '../lib/base_view'

module.exports = class ProgressbarView extends BaseView

    className: 'progress'
    template: require './templates/progressbar'
    value: 0

    constructor: (@model) ->
        console.log @model

        super()

    initialize: ->
        @listenTo @model, 'progress', @update
        @listenTo @model, 'sync', @destroy

    update: (e) ->
        pc = parseInt(e.loaded / e.total * 100)
        console.log "[Progress bar] : #{pc} %"

        @value = pc
        @render()

    getRenderData: ->
        value: @value
