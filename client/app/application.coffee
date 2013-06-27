module.exports =

    initialize: ->
        $.ajax('cozy-locale.json')
        .done( (data) => @locale = data.locale )
        .fail(     () => @locale = 'en'        )
        .always(   () => @initializeStep2()    )


    initializeStep2: ->

        @polyglot = new Polyglot()
        try
            locales = require 'locales/'+ @locale
        catch e
            locales = require 'locales/en'

        @polyglot.extend locales
        window.t = @polyglot.t.bind @polyglot

        ContactsCollection = require('collections/contact')
        ContactsList = require('views/contactslist')
        Router = require('router')

        @contacts = new ContactsCollection()
        @contactslist = new ContactsList collection: @contacts
        @contactslist.$el.appendTo $('body')
        @contactslist.render()
        @contacts.fetch()

        @router = new Router()

        Backbone.history.start()
