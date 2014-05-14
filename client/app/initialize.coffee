app = require 'application'

$ ->
    jQuery.event.props.push 'dataTransfer'
    locale = "en" # default locale

    # we'll need to tweak the server to allow this
    $.ajax "cozy-locale.json",
        success: (data) ->
            locale = data.locale
            initializeLocale locale
        error: ->
            initializeLocale locale


    # let's define a function to initialize Polyglot
    initializeLocale = (locale) ->
        locales = {}
        try
            locales = require("locales/" + locale)
        catch err
            locales = require("locales/en")
        polyglot = new Polyglot()

        # we give polyglot the data
        polyglot.extend locales

        # handy shortcut
        window.t = polyglot.t.bind(polyglot)

        # launch the app
        app.initialize()
