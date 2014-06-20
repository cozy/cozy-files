BaseView = require '../lib/base_view'

module.exports = class TagsView extends BaseView

    initialize: ->
        super

    afterRender: ->

        @$el.tagit
            availableTags: window.tags or []
            placeholderText: t 'tag'
            afterTagAdded: @tagAdded
            afterTagRemoved: @tagRemoved
            onTagClicked: @tagClicked

        # hack to prevent tagit events
        @duringRefresh = false

        $('.ui-widget-content .ui-autocomplete-input').keypress (event) ->
            keyCode = event.keyCode || event.which
            $('.zone .type').first().select() if keyCode is 9

        return this

    tagAdded: (event, ui) =>
        unless @duringRefresh or ui.duringInitialization
            @model.set 'tags', @$el.tagit 'assignedTags'
            @model.save()

    tagClicked: (event, ui) =>
        $("#search-box").val "tag:#{ui.tagLabel}"
        $("#search-box").trigger 'keyup'
        $(".dropdown-menu").hide()

    tagRemoved: (event, ui) =>
        unless @duringRefresh or ui.duringInitialization
            @model.set 'tags', @$el.tagit 'assignedTags'
            @model.save()

    refresh: =>
        @duringRefresh = true
        @$el.tagit 'removeAll'
        for tag in @model.get('tags')
            @$el.tagit 'createTag', tag
        @duringRefresh = false