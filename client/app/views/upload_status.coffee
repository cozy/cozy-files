BaseView = require '../lib/base_view'
File = require '../models/file'
ProgressBar = require '../widgets/progressbar'

module.exports = class UploadStatusView extends BaseView

    id: "upload-status"

    template: require './templates/upload_status'


    events: ->
        'click #dismiss': 'resetCollection'


    initialize: (options) ->
        super options
        @uploadQueue = options.uploadQueue

        @listenTo @collection, 'add', @uploadCount
        @listenTo @collection, 'remove', @uploadCount
        @listenTo @uploadQueue, 'reset', @render
        @listenTo @uploadQueue, 'upload-progress', @progress
        @listenTo @uploadQueue, 'upload-complete', @complete
        @listenTo @uploadQueue, 'upload-max-size-exceed', @error


    getRenderData: ->
        if @collection.progress
            {loadedBytes, totalBytes} = @collection.progress
            value = parseInt(100 * loadedBytes / totalBytes) + '%'
        else
            value = '0 %'

        return data =
            value: value
            collection: @collection


    progress: (e) ->
        @$el.removeClass 'success danger warning'
        progress = parseInt(100 * e.loadedBytes / e.totalBytes)
        percentage =  "#{progress}%"
        @progressbar.width percentage
        @progressbarContent.text "#{t('total progress')} : #{percentage}"


    complete: ->
        @$('.progress').remove()
        result = @uploadQueue.getResults()
        if result.success > 0 or result.errorList.length > 0 \
        or result.existingList.length > 0
            @dismiss.show()

            @$el.addClass result.status
            @$('span').text [
                if result.success
                    t 'upload complete', smart_count: result.success
                if result.existingList.length
                    @makeExistingSentence result.existingList

                if result.errorList.length
                    @makeErrorSentence result.errorList
            ].join ' '
        else
            @resetCollection()


    error: ({msg}) ->
        @$el.addClass 'warning'

        # Keep trace for debugging
        # because warning into view
        # will be re-write after complete
        console.error msg

        @$('span').text msg


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


    resetCollection: -> @uploadQueue.reset()


    uploadCount: (e) ->
        if @collection.length > 0
            @$el.show()
            $('#content').addClass 'mt108'
        else
            @render()

        @render() if @completed and not @collection.completed


    afterRender: ->
        @$el.removeClass 'success danger warning'

        @progressbar = @$ '.progress-bar-info'
        @progressbarContent = @$ '.progress-bar-content'
        @dismiss = @$('#dismiss').hide()

        if @collection.length is 0
            @$el.hide()
            $('#content').removeClass 'mt108'
        else
            $('#content').addClass 'mt108'

        if @uploadQueue.completed then @complete()
