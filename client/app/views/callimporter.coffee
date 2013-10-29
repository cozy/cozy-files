BaseView       = require 'lib/base_view'
CallLogReader  = require 'lib/call_log_reader'
ContactLogCollection = require 'collections/contactlog'
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
        @confirm_step = @$('#import-confirm').hide()
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

            content = log.content.message or
                @formatDuration log.content.duration

            html = '<tr>'
            html += "<td> #{log.direction} </td>"
            html += "<td> #{log.remote.tel} </td>"
            html += "<td> #{Date.create(log.timestamp).format()} </td>"
            html += "<td> #{content} </td>"
            html += '</tr>'
            @$('tbody').append $ html

        @toImport = toImport
        @confirmBtn.removeClass 'disabled'

    formatDuration: (duration) ->
        seconds = (duration % 60)
        minutes = (duration - seconds) % 3600
        hours = (duration - minutes - seconds)

        out = seconds + t('seconds')
        out = minutes/60 + t('minutes') + ' ' + out if minutes
        out = hours/3600 + t('hours') + ' ' + out if hours
        return out

    doImport: ->
        return if @confirmBtn.hasClass 'disabled'

        @parse_step.remove()
        @confirm_step.show()
        @confirmBtn.addClass 'disabled'

        req = $.ajax 'logs',
            type: 'POST'
            data: JSON.stringify new ContactLogCollection(@toImport).toJSON()
            contentType: 'application/json'
            dataType: 'json'

        req.done (data) =>
            if data.success then @close()
            else @showFaillure()

        req.fail @showFaillure

    showFaillure: =>
        @$('.modal-body').html '<p>' + t('import fail') + '</p>'
        @confirmBtn.remove()

    close: =>
        @$el.modal 'hide'
        app.router.navigate ''
        @remove()