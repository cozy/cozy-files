BaseView = require 'lib/base_view'

module.exports = class DocView extends BaseView

    id: 'doc'
    template: require 'templates/doc'

    events:
        'change #nameFormat': 'saveNameFormat'

    afterRender: ->
        @$('#nameFormat').val app.config.get 'nameOrder'

    saveNameFormat: ->
        help = @$('.help-inline').show().text t 'saving'
        app.config.save nameOrder: @$('#nameFormat').val(),
            wait: true
            success: ->
                help.text(t 'saved').fadeOut()

            error: ->
                help.addClass('error').text t 'server error occured'