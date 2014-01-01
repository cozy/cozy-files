BaseView = require 'lib/base_view'

module.exports = class TagsView extends BaseView

    initialize: ->
        super
        @$el.tagit
            availableTags: app.contacts.getTags() or []
            placeholderText: t 'add tags'
            afterTagAdded  : @tagAdded
            afterTagRemoved : @tagRemoved

        # hack to prevent tagit events
        @duringRefresh = false

        $('.ui-widget-content .ui-autocomplete-input').keypress (event) ->
            keyCode = event.keyCode || event.which
            $('.zone .type').first().select() if keyCode is 9
        return this

    tagAdded: (e, ui) =>
        unless @duringRefresh or ui.duringInitialization
            @model.set 'tags', @$el.tagit 'assignedTags'
            @options.onChange()
        ui.tag.click =>
            tagLabel = ui.tag.find('.tagit-label').text()
            $("#filterfield").val tagLabel
            $("#filterfield").trigger 'keyup'
            $(".dropdown-menu").hide()

    tagRemoved: (er, ui) =>
        unless @duringRefresh or ui.duringInitialization
            @model.set 'tags', @$el.tagit 'assignedTags'
            @options.onChange()

    refresh: =>
        @duringRefresh = true
        @$el.tagit 'removeAll'
        for tag in @model.get('tags')
            @$el.tagit 'createTag', tag
        @duringRefresh = false



