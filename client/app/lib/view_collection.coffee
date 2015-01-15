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

    bufferEl: null

    # Gets the selector of the item views
    getItemViewSelector: ->
        classNames = @itemview::className.replace ' ', '.'
        return "#{@itemview::tagName}.#{classNames}"

    # add 'empty' class to view when there is no subview
    onChange: ->
        @$el.toggleClass 'empty', @views.length

    # we append the views at a specific index
    # based on their order in the collection
    appendView: (view) ->
        index = @collection.indexOf view.model
        if index is 0 # insert at the beginning
            if @isBuffering
                @bufferEl.insertBefore view.el, @bufferEl.firstChild
            else
                @$collectionEl.prepend view.$el
        else
            if @isBuffering
                brother = @bufferEl.childNodes[index - 1]
                # if the user goes back and forth during upload
                # brother may not be defined
                if brother?
                    brotherAfter = brother.nextSibling
                    @bufferEl.insertBefore view.el, brotherAfter
            else
                selector = @getItemViewSelector()
                view.$el.insertAfter $(selector).eq index - 1

        ###
            If buffering is enabled, we batch all appendView to one DOM request
            thanks to a document fragment. Data are added one by one so we use
            a set timeout
        ###
        if @isBuffering
            clearTimeout @timeout
            @timeout = setTimeout =>
                @cleanBuffer()
            , 1

    # bind listeners to the collection
    initialize: ->
        super
        @views = []
        @listenTo @collection, "reset",   @onReset
        @listenTo @collection, "add",     @addItem
        @listenTo @collection, "remove",  @removeItem
        @listenTo @collection, "sort",    @onSort

        @collectionEl = el if not @collectionEl?

        # we only use buffer for the first render
        @initializeBuffering()

    # enable buffering
    initializeBuffering: ->
        @isBuffering = true
        @bufferEl = document.createDocumentFragment()

    # append the buffer to the DOM, removes it and disable buffering
    cleanBuffer: ->
        if @isBuffering
            @isBuffering = false
            @$collectionEl.html @bufferEl
            @bufferEl = null

    # if we have views before a render call, we detach them
    render: ->
        _.each @views, (view) -> view.$el.detach()
        super

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
