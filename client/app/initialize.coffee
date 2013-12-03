app = require 'application'

$ ->
    jQuery.event.props.push 'dataTransfer'

    # Initialize Spin JS the lib that displays loading indicators
    $.fn.spin = (opts, color) ->
        presets =
            tiny:
                lines: 8
                length: 2
                width: 2
                radius: 3

            small:
                lines: 8
                length: 1
                width: 2
                radius: 5

            large:
                lines: 10
                length: 8
                width: 4
                radius: 8

        if Spinner
            @each ->
                $this = $(this)
                spinner = $this.data("spinner")
                if spinner?
                    spinner.stop()
                    $this.data "spinner", null
                else if opts isnt false
                    if typeof opts is "string"
                        if opts of presets
                            opts = presets[opts]
                        else
                            opts = {}
                        opts.color = color if color
                    spinner = new Spinner(
                        $.extend(color: $this.css("color"), opts))
                    spinner.spin(this)
                    $this.data "spinner", spinner

        else
            console.log "Spinner class not available."
            nullapp = require 'application'



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
