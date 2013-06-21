module.exports =

    initialize: ->
        @polyglot = new Polyglot()
        @polyglot.extend require('locales/en')
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
