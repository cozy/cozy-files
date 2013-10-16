BaseView       = require 'lib/base_view'
CallLogReader  = require 'lib/call_log_reader'
app            = require 'application'

module.exports = class CallImporterView extends BaseView

    template: require 'templates/callimporter'

    id: 'callimporter'
    tagName: 'div'
    className: 'modal fade'

    events: ->
        'change #csvupload': 'onUpload'
        'click  #confirm-btn': 'doImport'

    afterRender: ->
        @$el.modal('show')
        @upload = @$('#csvupload')[0]
        @file_step = @$('#import-file')
        @parse_step = @$('#import-config').hide()
        @confirmBtn = @$('#confirm-btn')

    onUpload: ->
        file = @upload.files[0]

        reader = new FileReader()
        reader.readAsText file
        reader.onloadend = =>
            try
                @toImport = CallLogReader.parse reader.result
                @onLogFileParsed()
            catch error
                @$('.control-group').addClass 'error'
                @$('.help-inline').text t 'failed to parse'

        reader.onerror = =>
            console.log "ERROR READING", reader.result, reader.error


    onLogFileParsed: ->
        @file_step.remove()
        @parse_step.show()

        for log in @toImport
            html = '<tr>'
            for field in ['direction', 'number', 'datetime']
                html += "<td> #{log[field]} </td>"
            html += '</tr>'
            @$('tbody').append $ html

        @confirmBtn.removeClass 'disabled'

    doImport: ->
        return true unless @toImport

        @toImport.each (contact) ->
            contact.save null,
                success: ->
                    app.contacts.add contact

        @close()

    close: ->
        @$el.modal 'hide'
        @remove()