BaseView = require '../lib/base_view'

module.exports = class TagsView extends BaseView

    initialize: ->
        super
        @$el.tagit
            availableTags: []  # TODO: get list of current tags from db
            placeholderText: t 'tag'
            afterTagAdded: @tagAdded
            afterTagRemoved: @tagRemoved

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

        ui.tag.click =>
            tagLabel = ui.tag.find('.tagit-label').text()
            $("#filterfield").val tagLabel
            $("#filterfield").trigger 'keyup'
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
