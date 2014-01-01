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
        "keyup": "onKeyUp"

    initialize: ->
        super
        @listenTo @collection, 'change', @onContactChanged

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
        @activatedModel = model

    cleanFilter: (event) ->
        event.preventDefault()
        @filterfield.val('')
        @filterClean.hide()
        view.$el.show() for id, view of @views

    getTags: => @collection.getTags()

    onContactChanged: (model) =>
        @views[model.cid].render()
        @activate model

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

    # If arrow key is up, it selects the contact that is listed above the
    # currently selected contact.
    # If arrow key is down, it selects the contact that is listed below the
    # currently selected contact.
    onKeyUp: (event) =>
        if @activatedModel?
            keyCode = event.keyCode
            keyCode ?= event.which
            if keyCode is 38
                @onArrowUp @activatedModel
            else if keyCode is 40
                @onArrowDown @activatedModel

    # Selects the contact that is currently above the currently selected
    # contact by updating the route url with the contact ID.
    onArrowUp: (contact) ->
        prevLine = @views[contact.cid].$el.prev()
        while prevLine.length and prevLine.is ':hidden'
            prevLine = prevLine.prev()
        if prevLine.length
            App.router.navigate prevLine.attr('href'), true

    # Selects the contact that is currently below the currently selected
    # contact by updating the route url with the contact ID.
    onArrowDown: (contact) ->
        nextLine = @views[contact.cid].$el.next()
        while nextLine.length and nextLine.is ':hidden'
            nextLine = nextLine.next()
        if nextLine.length
            App.router.navigate nextLine.attr('href'), true
