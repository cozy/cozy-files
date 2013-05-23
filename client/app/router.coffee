app              = require 'application'
ContactView      = require 'views/contact'
HelpView         = require 'views/help'
Contact          = require 'models/contact'

module.exports = class Router extends Backbone.Router
    routes:
        ''                    : 'help'
        'contact/new'         : 'newcontact'
        'contact/:id'         : 'showcontact'

    help: ->
        @displayView new HelpView()

    newcontact: ->
        contact = new Contact()
        contact.once 'change:id', =>
            app.contacts.add contact
            @navigate "contact/#{contact.id}", false
        @displayViewFor contact
        $('#name').focus()

    showcontact: (id) ->
        # may be wait for contacts to load
        if app.contacts.length is 0
            app.contacts.once 'sync', => @showcontact id
            return

        contact = app.contacts.get(id)

        if contact
            @displayViewFor contact

        else
            alert "this contact doesn't exist"
            @navigate '', false


    # helpers
    displayView: (view) ->
        @stopListening @currentContact if @currentContact

        if app.contactview?.needSaving
            app.contactview.save()
            app.contactview.once 'sync', => @displayView view
            return

        app.contactview.remove() if app.contactview
        app.contactview = view
        app.contactview.render()
        app.contactview.$el.appendTo $('body')

    displayViewFor: (contact) ->
        @currentContact = contact
        @displayView new ContactView model: contact
        @listenTo contact, 'destroy', -> @navigate '', true
