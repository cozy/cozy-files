app = require 'widget'

$ ->
    jQuery.event.props.push 'dataTransfer'
    app.initialize()
