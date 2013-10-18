$ ->

    homeGoTo = (url) ->
        intent =
            action: 'goto'
            params: url

        window.parent.postMessage intent, window.location.origin

    @locale = window.locale
    delete window.locale

    @polyglot = new Polyglot()
    try
        locales = require 'locales/'+ @locale
    catch e
        locales = require 'locales/en'

    @polyglot.extend locales
    window.t = @polyglot.t.bind @polyglot

    class Router extends Backbone.Router
        routes:
            '': ->
            '*redirect': 'redirect'
        redirect: (path) ->
            @navigate '#', trigger: true
            homeGoTo 'contacts/' + path

    ContactsCollection = require('collections/contact')
    ContactsList = require('views/contactslist')
    @contacts = new ContactsCollection()
    @contactslist = new ContactsList collection: @contacts
    @contactslist.$el.appendTo $('body')
    @contactslist.render()
    @contacts.reset window.initcontacts, parse: true
    delete window.initcontacts

    router = new Router()
    Backbone.history.start()
