BaseView = require '../lib/base_view'

module.exports = class ProgressbarView extends BaseView

    className: 'progressview'
    template: require './templates/progressbar'
    value: 0

    constructor: (@model) ->
        super()

    initialize: ->
        @listenTo @model, 'progress', @update
        @listenTo @model, 'sync', @destroy

    update: (e) ->
        pc = parseInt(e.loaded / e.total * 100)
        @value = pc
        @render()

    getRenderData: ->
        value: @value
        name: @model.get 'name'
