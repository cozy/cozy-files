BaseView = require 'lib/base_view'

module.exports = class TagsView extends BaseView

    initialize: ->
        @$el.tagit
            availableTags: []
            placeholderText: t 'add tags'
            afterTagAdded  : @tagAdded
            afterTagRemoved : @tagRemoved

        # hack to prevent tagit events
        @myOperation = false

        return this

    tagAdded: (e, ui) =>
        unless @myOperation or ui.duringInitialization
            @model.set 'tags', @$el.tagit 'assignedTags'
            @options.onChange()
        ui.tag.click =>
            tagLabel = ui.tag.find('.tagit-label').text()
            $("#filterfield").val tagLabel
            $("#filterfield").trigger 'keyup'
            $(".dropdown-menu").hide()

    tagRemoved: (er, ui) =>
        unless @myOperation or ui.duringInitialization
            @model.set 'tags', @$el.tagit 'assignedTags'
            @options.onChange()

    refresh: =>
        @myOperation = true
        @$el.tagit 'removeAll'
        for tag in @model.get('tags')
            @$el.tagit 'createTag', tag
        @myOperation = false



