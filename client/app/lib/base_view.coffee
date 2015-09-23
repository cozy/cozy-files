module.exports = class BaseView extends Backbone.View

    template: ->

    initialize: ->

    getRenderData: ->
        model: @model?.toJSON()

    render: ->
        @beforeRender()
        @$el.html @template @getRenderData()
        @afterRender()
        return @

    beforeRender: ->

    afterRender: ->

    destroy: -> @remove()
