ViewCollection = require 'lib/view_collection'
App            = require 'application'

# "Home" view : the list of contacts
# simple ViewCollection

module.exports = class ContactsList extends ViewCollection

    id: 'contacts-list'
    itemView: require 'views/contactslist_item'
    template: require 'templates/contactslist'

    events:
        'change #filterfield': 'keyUpCallback'
        'click #filterClean': 'cleanFilter'

    afterRender: ->
        super
        @list        = @$ '#contacts'
        @filterfield = @$ '#filterfield'
        @filterClean = @$ '#filterClean'
        @filterClean.hide()
        @filterfield.focus()
        @list.niceScroll()
        # fucking bootstrap
        @filterfield.keyup @keyUpCallback
        @filterfield.typeahead source: @getTags


    remove: ->
        super
        @list.getNiceScroll().remove()

    appendView: (view) ->
        @list.append view.$el

    activate: (model) ->
        @$('.activated').removeClass 'activated'
        return unless model
        line = @views[model.cid].$el
        line.addClass 'activated'

        position = line.position().top
        outofview = position < 0 or position > @list.height()
        @list.scrollTop @list.scrollTop() + position if outofview

    cleanFilter: (event) ->
        event.preventDefault()
        @filterfield.val('')
        @filterClean.hide()
        view.$el.show() for id, view of @views

    getTags: => @collection.getTags()

    keyUpCallback: (event) =>

        if event.keyCode is 27 #ESC
            @filterfield.val('')
            @filterClean.hide()
            App.router.navigate "", true

        filtertxt = @filterfield.val()
        @filterClean.show()

        return unless filtertxt.length > 1 or filtertxt.length is 0

        @filterClean.toggle filtertxt.length isnt 0

        filtertxt = filtertxt.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')
        @filter    = new RegExp filtertxt, 'i'

        firstmodel = null

        for id, view of @views
            match = (filtertxt is '0') or view.model.match @filter
            view.$el.toggle match

            firstmodel = view.model if match and not firstmodel

        if firstmodel and event.keyCode is 13
            App.router.navigate "contact/#{firstmodel.id}", true
