BaseView = require '../lib/base_view'

module.exports = class BreadcrumbsView extends BaseView

    itemview: require './templates/breadcrumbs_element'
    tagName: "ul"

    constructor: (@collection) ->
        super()

    initialize: ->
        @listenTo @collection, "reset",   @render
        @listenTo @collection, "add",     @render
        @listenTo @collection, "remove",  @render

    render: ->
        @$el.html ""
        for folder in @collection.models
            @$el.append @itemview(model: folder)
        @
