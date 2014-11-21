module.exports = class BaseView extends Backbone.View

    template: ->

    initialize: ->

    getRenderData: ->
        model: @model?.toJSON()

    render: ->
        @beforeRender()
        @$el.html @template @getRenderData()
        @afterRender()
        @

    beforeRender: ->

    afterRender: ->

    destroy: -> @remove()
