BaseView = require 'lib/base_view'

module.exports = class TagsView extends BaseView

    initialize: ->
        @$el.tagit
            availableTags: ['test', 'toast']
            placeholderText: t 'add tags'
            afterTagAdded  : @tagAdded
            afterTagRemoved : @tagRemoved

        # hack to prevent tagit events
        @myOperation = false

        return this

    tagAdded: (e, ui) =>
        unless @myOperation or ui.duringInitialization
            @model.set 'tags', @$el.tagit 'assignedTags'
            @options.contactView.changeOccured()

    tagRemoved: (er, ui) =>
        unless @myOperation or ui.duringInitialization
            @model.set 'tags', @$el.tagit 'assignedTags'
            @options.contactView.changeOccured()

    refresh: =>
        @myOperation = true
        @$el.tagit 'removeAll'
        for tag in @model.get('tags')
            @$el.tagit 'createTag', tag
        @myOperation = false



