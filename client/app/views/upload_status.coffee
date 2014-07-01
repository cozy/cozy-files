BaseView = require '../lib/base_view'
File = require '../models/file'
ProgressBar = require '../widgets/progressbar'

UploadedFileView = require './uploaded_file_view'

module.exports = class UploadStatusView extends BaseView

    id: "upload-status"
    template: require './templates/upload_status'

    events: ->
        'click .confirm': 'resetCollection'

    initialize: ->
        super
        @listenTo @collection, 'add', @uploadCount
        @listenTo @collection, 'remove', @uploadCount
        @listenTo @collection, 'reset', @render
        @listenTo @collection, 'upload-progress', @progress
        @listenTo @collection, 'upload-complete', @complete

    getRenderData: ->
        e = @collection.progress
        value = if e then parseInt(100 * e.loadedBytes / e.totalBytes) + '%'
        else '0 %'

        return data =
            value: value
            collection: @collection

    progress: (e) ->
        @$el.removeClass 'success danger warning'
        p = parseInt(100 * e.loadedBytes / e.totalBytes) + '%'
        @progressbar.text("#{t('total progress')} : #{p}").width(p)

    complete: ->
        @$('.progress').remove()
        @$('.btn-success').text('Ok').addClass('confirm')

        result = @collection.getResults()

        @$el.addClass result.status
        @$('span').text [
            if result.success
                t 'upload complete', smart_count: result.success
            if result.existing.length
                @makeExistingSentence(result.existing)

            if result.error.length
                @makeErrorSentence(result.error)
        ].join ' '

    # generate a sentence explaining existing files
    makeExistingSentence: (existing) ->
        parts = [existing[0].get('name')]
        if existing.length > 1
            parts.push t('and x files', smart_count: existing.length - 1)
        parts.push t 'already exists'

        return parts.join ' '

    # generate a sentence explaining error files
    makeErrorSentence: (errors) ->
        parts = [errors[0].get('name')]
        if errors.length > 1
            parts.push t('and x files', smart_count: errors.length - 1)
        parts.push t 'failed to upload'

        return parts.join ' '

    resetCollection: ->
        @collection.reset()

    uploadCount: (e) ->
        @$el.slideDown() if @collection.length
        @render() if @completed and not @collection.completed
        @counter.text @collection.length
        @counterDone.text @collection.loaded

    afterRender: ->
        @$el.removeClass 'success danger warning'
        @$el.hide() unless @collection.length
        @counter = @$('.counter')
        @counterDone = @$('.counter-done')
        @progressbar = @$('.progress-bar')
        if @collection.completed then @complete()

