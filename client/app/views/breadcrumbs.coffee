BaseView = require '../lib/base_view'

module.exports = class BreadcrumbsView extends BaseView

    itemview: require './templates/breadcrumbs_element'
    tagName: "ul"

    # collection is a simple array, not a backbone collection
    render: ->
        opacity = if @collection.length is 1 then '0.5' else '1'
        @$el.css 'opacity', opacity

        @$el.empty()
        for folder in @collection
            @$el.append @itemview model: folder
        @

