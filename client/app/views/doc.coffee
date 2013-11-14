BaseView = require 'lib/base_view'

module.exports = class DocView extends BaseView

    id: 'doc'
    template: require 'templates/doc'

    events:
        'change #nameFormat': 'saveNameFormat'

    afterRender: ->
        if app.config.get('nameOrder') isnt 'not-set'
            @$('#config-now').hide()
            @$('#nameFormat').val app.config.get 'nameOrder'

        else if app.contacts.length is 0
            @$('#config-now').hide()

    saveNameFormat: ->
        help = @$('.help-inline').show().text t 'saving'
        app.config.save nameOrder: @$('#nameFormat').val(),
            wait: true
            success: ->
                help.text(t 'saved').fadeOut()
                window.location.reload()

            error: ->
                help.addClass('error').text t 'server error occured'
