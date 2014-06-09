BaseView = require '../lib/base_view'

module.exports = class ProgressbarView extends BaseView

    className: 'progressview'
    template: require './templates/progressbar'
    value: 0

    initialize: ->
        @listenTo @model, 'progress', @update
        @listenTo @model, 'sync', @destroy

        @value = parseInt(@model.loaded / @model.total * 100)

    update: (e) ->
        @value = parseInt(e.loaded / e.total * 100)
        @render()

    getRenderData: ->
        value: @value
        name: @model.get 'name'
