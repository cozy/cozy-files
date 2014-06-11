ProgressBar = require './progressbar'

BaseView = require '../lib/base_view'
module.exports = class UploadedFileView extends BaseView

    className: 'upload-progress-item'

    initialize: (options) ->
        super options

        @isDone = false
        @listenTo @model, 'sync', =>
            @isDone = true
            @render()

    template: ->
        content = $ """
            <div class="progress-name">
                <span class="name">#{@model.get('name')}</span>
            </div>
        """
        if @model.error
            content.append """
            <span class="error"> : #{@model.error}</span>
            """
        else if @isDone or @model.isUploaded
            content.append """
            <span class="success">#{t 'upload success'}</span>
            """
        else
            content.append new ProgressBar(model: @model).render().$el

        return content

        destroy: ->
            @stopListening @model
            super()