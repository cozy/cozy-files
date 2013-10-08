BaseView = require '../lib/base_view'

module.exports = class FileListsItemView extends BaseView

    # This time the html component does not exist in the dom.
    # So, we don't refer to a DOM element, we just give
    # class and tag names to let backbone build the component.
    className: 'file'
    tagName: 'div'

    # The template render the bookmark with data given by the model
    template: require './templates/fileslist_item'
    # Register event

    events:
        'click button.delete': 'onDeleteClicked'

    initialize: ->
        @listenTo @model, 'change:id', => @render()

    onDeleteClicked: ->
        if confirm 'Are you sure ?'
            @$('button.delete').html "deleting..."
            @model.destroy
                error: ->
                    alert "Server error occured, file was not deleted."
                    @$('button.delete').html "delete"