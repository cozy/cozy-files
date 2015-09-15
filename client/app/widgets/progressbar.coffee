BaseView = require '../lib/base_view'

module.exports = class ProgressbarView extends BaseView

    className: 'progressview'
    template: require '../views/templates/progressbar'
    value: 0

    initialize: ->
        @listenTo @model, 'progress', @update
        @listenTo @model, 'sync', @destroy

        @value = @getProgression @model.loaded, @model.total

    update: (e) ->
        @value = @getProgression e.loaded, e.total
        @$('.progress-bar').text(@value + '%').width @value + '%'

    getProgression: (loaded, total) ->
        return parseInt(loaded / total * 100)

    getRenderData: ->
        value: @value
        name: @model.get 'name'
