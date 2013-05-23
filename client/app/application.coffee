module.exports =

    initialize: ->
        ContactsCollection = require('collections/contact')
        ContactsList = require('views/contactslist')
        Router = require('router')

        @contacts = new ContactsCollection()
        @contactslist = new ContactsList collection: @contacts
        @contactslist.render()
        @contactslist.$el.appendTo $('body')
        @router = new Router()

        Backbone.history.start()
