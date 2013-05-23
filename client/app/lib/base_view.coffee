# BaseView used to DRY other views
# - copy view options in view object
# - pass the options, as well as getRenderData to the template
# - render the template inside its el
# provide a afterRender hook

module.exports = class BaseView extends Backbone.View
    initialize: (options) ->
        @options = options

    template: ->

    getRenderData: ->

    render: =>
        data = _.extend {}, @options, @getRenderData()
        @$el.html @template(data)
        @afterRender()
        this

    afterRender: ->
