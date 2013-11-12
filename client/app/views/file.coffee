BaseView = require '../lib/base_view'

module.exports = class FileView extends BaseView

    className: 'folder-row'
    tagName: 'tr'
    template: require './templates/file'

    events:
        'click a.file-delete': 'onDeleteClicked'

    initialize: ->
        @listenTo @model, 'change:id', => @render()

    onDeleteClicked: ->
        if confirm 'Are you sure ?'
            @model.destroy
                error: ->
                    alert "Server error occured, file was not deleted."