BaseView = require '../lib/base_view'

module.exports = class FolderListsItemView extends BaseView

    # This time the html component does not exist in the dom.
    # So, we don't refer to a DOM element, we just give
    # class and tag names to let backbone build the component.
    className: 'folder'
    tagName: 'div'

    # The template render the bookmark with data given by the model
    template: require './templates/folderslist_item'

    # Register event
    events: ->
        'click button.delete': 'onDeleteClicked'
        'click .show-button': 'onShowClicked'

    initialize: ->
        super
        @listenTo @model, 'change:id', => @render()
        @listenTo @model, 'change:name', => @render()

    onDeleteClicked: ->
        if confirm 'Are you sure ?'
            @model.destroy
                error: ->
                    alert "Server error occured, folder was not deleted."

