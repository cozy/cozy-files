module.exports =

    initialize: ->

        window.app = @

        @locale = window.locale
        delete window.locale

        @polyglot = new Polyglot()
        try
            locales = require 'locales/'+ @locale
        catch e
            locales = require 'locales/en'

        @polyglot.extend locales
        window.t = @polyglot.t.bind @polyglot

        ContactsCollection = require('collections/contact')
        ContactsList = require('views/contactslist')
        Config = require('models/config')
        Router = require('router')

        @contacts = new ContactsCollection()
        @contactslist = new ContactsList collection: @contacts
        @contactslist.$el.appendTo $('body')
        @contactslist.render()

        @config = new Config(window.config or {})
        delete window.config

        if window.initcontacts?
            @contacts.reset window.initcontacts, parse: true
            delete window.initcontacts
        else
            @contacts.fetch()

        @router = new Router()


        Backbone.history.start()
