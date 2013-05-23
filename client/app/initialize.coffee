app = require 'application'

$ ->
    jQuery.event.props.push 'dataTransfer'
    app.initialize()
