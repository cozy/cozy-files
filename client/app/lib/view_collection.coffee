BaseView = require 'lib/base_view'

# View that display a collection of subitems
# used to DRY views
# Usage : new ViewCollection(collection:collection)
# Automatically populate itself by creating a itemView for each item
# in its collection

# can use a template that will be displayed alongside the itemViews

# itemView       : the Backbone.View to be used for items
# itemViewOptions : the options that will be passed to itemViews
# collectionEl : the DOM element's selector where the itemViews will
#                be displayed. Automatically falls back to el if null

module.exports = class ViewCollection extends BaseView

    collectionEl: null
    template: -> ''
    itemview: null
    views: []


    itemViewOptions: ->


    # Gets the selector of the item views
    getItemViewSelector: ->
        classNames = @itemview::className.replace ' ', '.'
        return "#{@itemview::tagName}.#{classNames}"


    # bind listeners to the collection
    initialize: ->
        super
        @views = []
        @listenTo @collection, "reset",   @onReset
        @listenTo @collection, "add",     @addItem
        @listenTo @collection, "remove",  @removeItem
        @listenTo @collection, "sort",    @onSort

        @collectionEl = el unless @collectionEl?


    # after render, we reattach the views
    afterRender: ->
        @$collectionEl = $ @collectionEl
        @onReset @collection
        @onChange @views


    # destroy all sub views before remove
    remove: ->
        @onReset []
        super


    # event listener for reset
    onReset: (newcollection) ->
        _.each @views, (view) => @removeItem view.model
        newcollection.forEach @addItem


    # event listeners for add
    addItem: (model) =>
        options = _.extend {}, model: model, @itemViewOptions(model)
        view = new @itemview options
        @views.push view.render()
        @appendView view
        @onChange @views


    # event listeners for remove
    removeItem: (model) =>
        item = _.find @views, (view) -> view.model.cid is model.cid
        item.remove()
        @views.splice _.indexOf(@views, item), 1

        @onChange @views


    # We don't re-render the view if the order has not changed
    # Based on Marionette.ViewCollection
    onSort: ->
        selector = @getItemViewSelector()
        $itemViews = $ selector
        orderChanged = @collection.find (item, index) =>
            view = _.find @views, (view) -> view.model.cid is item.cid
            indexView = $itemViews.index view.$el
            return view and indexView isnt index

        @render() if orderChanged
