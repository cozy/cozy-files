ViewCollection = require 'lib/view_collection'
App            = require 'application'

# "Home" view : the list of contacts
# simple ViewCollection

module.exports = class ContactsList extends ViewCollection

    id: 'contacts-list'
    itemView: require 'views/contactslist_item'
    template: require 'templates/contactslist'

    events:
        'keyup #filterfield': 'keyUpCallback'

    afterRender: ->
        super
        @collection.fetch()
        @list        = @$ '#contacts'
        @filterfield = @$ '#filterfield'
        @filterfield.focus()

    appendView: (view) ->
        @list.append view.$el

    keyUpCallback: (event) ->

        if event.keyCode is 27 #ESC
            @filterfield.val('')
            App.router.navigate "", true

        @filtertxt = @filterfield.val()
        @filtertxt = @filtertxt.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')
        @filter    = new RegExp @filtertxt, 'i'

        firstmodel = null

        for id, view of @views
            match = (@filtertxt is '') or view.model.match @filter
            view.$el.toggle match

            firstmodel = view.model if match and not firstmodel

        if firstmodel and event.keyCode is 13
            App.router.navigate "contact/#{firstmodel.id}", true
