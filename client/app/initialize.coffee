app = require 'application'

$ ->
    jQuery.event.props.push 'dataTransfer'

    if window.domain is "false"
        app.domain = "#{window.location.origin}/public/files/"
    else
        app.domain = window.domain

    locale = window.locale or "en" # default locale
    moment.lang locale

    locales = {}
    try
        locales = require "locales/#{locale}"
    catch err
        locales = require "locales/en"

    polyglot = new Polyglot()

    # we give polyglot the data
    polyglot.extend locales

    # handy shortcut
    window.t = polyglot.t.bind polyglot

    # init plugins
    require("./utils/plugin_utils").init()

    # keeps count of operations in progress
    window.pendingOperations =
        upload: 0
        move: 0
        deletion: 0

    # launch the app
    app.initialize()

# Asks the user if he tries to reload the page while an operation is in progress
window.onbeforeunload = ->

    values = _.values window.pendingOperations
    sum = (a, b) -> a + b
    pendingOperationsNum = _.reduce values, sum, 0
    if pendingOperationsNum > 0
        return t 'confirmation reload'

