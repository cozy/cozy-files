module.exports =

    initialize: ->
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
