app              = require 'application'
ContactView      = require 'views/contact'
DocView          = require 'views/doc'
ImporterView     = require 'views/importer'
CallImporterView     = require 'views/callimporter'
Contact          = require 'models/contact'

module.exports = class Router extends Backbone.Router
    routes:
        ''                    : 'help'
        'import'              : 'import'
        'callimport'          : 'callimport'
        'contact/new'         : 'newcontact'
        'contact/:id'         : 'showcontact'

    initialize: ->
        $('body').on 'keyup', (event) =>
            @navigate "", true if event.keyCode is 27 #ESC

    help: ->
        @displayView new DocView()
        $('#filterfied').focus()
        app.contactslist.activate null

    import: ->
        @help()
        @importer = new ImporterView()
        $('body').append @importer.render().$el

    callimport: ->
        @help()
        @importer = new CallImporterView()
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
            app.contactslist.activate contact

        else
            alert t "this contact doesn't exist"
            @navigate '', true


    # helpers
    displayView: (view) ->
        @stopListening @currentContact if @currentContact

        if app.contactview?.needSaving and confirm t 'Save changes ?'
            app.contactview.save()
            app.contactview.model.once 'sync', => @displayView view
            return

        @importer.close() if @importer
        @importer = null

        app.contactview.remove() if app.contactview
        app.contactview = view
        app.contactview.$el.appendTo $('body')
        app.contactview.render()

    displayViewFor: (contact) ->
        @currentContact = contact
        @displayView new ContactView model: contact
        @listenTo contact, 'destroy', -> @navigate '', true
