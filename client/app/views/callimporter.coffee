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

    getRenderData: ->
        countries: require('lib/phone_number').countries

    afterRender: ->
        @$el.modal('show')
        @upload = @$('#csvupload')[0]
        @country = @$('#phonecountry')
        @file_step = @$('#import-file')
        @parse_step = @$('#import-config').hide()
        @confirmBtn = @$('#confirm-btn')

    onUpload: ->
        file = @upload.files[0]
        country = @country.val()

        reader = new FileReader()
        reader.readAsText file
        reader.onloadend = =>
            try
                CallLogReader.parse reader.result, country, @onLogFileParsed, @onLogFileProgress
            catch error
                console.log error.stack
                @$('.control-group').addClass 'error'
                @$('.help-inline').text t 'failed to parse'

        reader.onerror = =>
            console.log "ERROR READING", reader.result, reader.error

    onLogFileProgress: (done, total) =>
        p = Math.round(100 * done/total)
        @$('.help-inline').text t('progress') + ": #{p}%"

    onLogFileParsed: (err, toImport) =>
        if err
            console.log error.stack
            @$('.control-group').addClass 'error'
            @$('.help-inline').text t 'failed to parse'
            return

        @file_step.remove()
        @parse_step.show()

        for log in toImport
            html = '<tr>'
            html += "<td> #{log.direction} </td>"
            html += "<td> +#{log.remote.tel} </td>"
            html += "<td> #{Date.create(log.timestamp).format()} </td>"
            html += '</tr>'
            @$('tbody').append $ html

        @confirmBtn.removeClass 'disabled'

    doImport: ->


    close: ->
        @$el.modal 'hide'
        @remove()