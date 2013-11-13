BaseView = require 'lib/base_view'

module.exports = class DocView extends BaseView

    id: 'doc'
    template: require 'templates/doc'

    events:
        'change #nameFormat': 'saveNameFormat'

    saveNameFormat: ->
        field = @$('#nameFormat')
        #field.spin('small')
        app.config.save nameOrder: field.val(),
            wait: true
            error: ->
                alert('server error occured')
            always: ->
                #field.spin()
