BaseView = require '../lib/base_view'
File = require '../models/file'
ProgressBar = require '../widgets/progressbar'

UploadedFileView = require './uploaded_file_view'

module.exports = class UploadStatusView extends BaseView

    id: "upload-status"
    template: require './templates/upload_status'

    events: ->
        'click #dismiss': 'resetCollection'

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
        percentage = parseInt(100 * e.loadedBytes / e.totalBytes) + '%'
        @progressbar.width percentage
        @progressbarContent.text "#{t('total progress')} : #{percentage}"

    complete: ->
        @$('.progress').remove()
        result = @collection.getResults()
        if result.success > 0 or result.error > 0 or result.existing > 0
            @dismiss.show()

            @$el.addClass result.status

            @$('span').text [
                if result.success
                    t 'upload complete', smart_count: result.success
                if result.existing.length
                    @makeExistingSentence result.existing

                if result.error.length
                    @makeErrorSentence result.error
            ].join ' '
        else
            @resetCollection()

    # generate a sentence explaining existing files
    makeExistingSentence: (existing) ->
        parts = [existing[0].get('name')]
        if existing.length > 1
            parts.push t('and x files', smart_count: existing.length - 1)
        parts.push t 'already exists'

        return parts.join ' '

    # generate a sentence explaining error files
    makeErrorSentence: (errors) ->
        parts = []
        parts.push "#{errors.pop().get 'name'}"
        if errors.length > 1
            parts.push t 'and x files', smart_count: errors.length - 1
        parts.push t 'failed to upload', smart_count: errors.length - 1
        if errors.length > 1
            parts.push ': '
            parts.push "#{errors.pop().get 'name'}"
            parts.push ", #{error.get 'name'}" for error in errors

        return parts.join ' '

    resetCollection: ->
        alert "clear collection"
        @collection.reset()
        # Force hiding of the upload status widget. In case of afterRender
        # is called too early.
        setTimeout =>
            @$el.hide()
            $('#content').css 'margin-top': 56
        , 200

    uploadCount: (e) ->
        if @collection.length
            @$el.slideDown easing: 'linear'
            $('#content').animate 'margin-top': 108,
                easing: 'linear'

        @render() if @completed and not @collection.completed
        @counter.text @collection.length
        @counterDone.text @collection.loaded

    afterRender: ->
        unless @collection.length
            @$el.hide()
            $('#content').css 'margin-top': 56
        else
            $('#content').css 'margin-top': 108

        @$el.removeClass 'success danger warning'
        @counter = @$ '.counter'
        @counterDone = @$ '.counter-done'
        @progressbar = @$ '.progress-bar-info'
        @progressbarContent = @$ '.progress-bar-content'
        @dismiss = @$('#dismiss').hide()
        if @collection.completed then @complete()

