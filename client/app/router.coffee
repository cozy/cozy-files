app              = require 'application'
ContactView      = require 'views/contact'
HelpView         = require 'views/help'
ImporterView     = require 'views/importer'
Contact          = require 'models/contact'

module.exports = class Router extends Backbone.Router
    routes:
        ''                    : 'help'
        'import'              : 'import'
        'contact/new'         : 'newcontact'
        'contact/:id'         : 'showcontact'

    initialize: ->
        $('body').on 'keyup', (e) =>
            @navigate "", true if event.keyCode is 27 #ESC

    help: ->
        @displayView new HelpView()

    import: ->
        @help()
        @importer = new ImporterView()
        $('body').append @importer.render().$el

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
            @navigate '', true


    # helpers
    displayView: (view) ->
        @stopListening @currentContact if @currentContact

        if app.contactview?.needSaving
            app.contactview.save()
            app.contactview.once 'sync', => @displayView view
            return

        @importer.close() if @importer
        @importer = null

        app.contactview.remove() if app.contactview
        app.contactview = view
        app.contactview.render()
        app.contactview.$el.appendTo $('body')

    displayViewFor: (contact) ->
        @currentContact = contact
        @displayView new ContactView model: contact
        @listenTo contact, 'destroy', -> @navigate '', true
