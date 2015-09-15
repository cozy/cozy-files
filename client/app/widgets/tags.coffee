BaseView = require '../lib/base_view'
Autocomplete = require './autocomplete'

module.exports = class TagsView extends BaseView

    events: ->
        'click .tag': 'tagClicked'
        'click .tag .deleter': 'deleteTag'
        'focus input': 'onFocus'
        'keydown input': 'onKeyDown'
        'keyup input': 'refreshAutocomplete'

    template: -> """
        <input type="text" placeholder="#{t('tag')}">
    """

    initialize: ->
        tags = @model.get('tags')
        tags ?= []
        @tags = []
        @tags.push tag for tag in tags when tag?
        @listenTo @model, 'change:tags', =>
            @tags = @model.get('tags')
            @refresh()

    onFocus: (e) ->
        TagsView.autocomplete.bind this.$el
        TagsView.autocomplete.refresh '', @tags
        if @input.val() is ''
            TagsView.autocomplete.$el.hide()
        else
            TagsView.autocomplete.$el.show()

    onKeyDown: (e) =>

        val = @input.val()

        if val is '' and e.keyCode is 8 #BACKSPACE
            @setTags @tags[0..-2] # remove last tag
            @refresh()
            TagsView.autocomplete.refresh('', @tags)
            TagsView.autocomplete.position()
            e.preventDefault()
            e.stopPropagation()
            return

        # COMMA, SPACE, TAB, ENTER
        if val and e.keyCode in [188, 32, 9, 13]
            @tags ?= []
            @tags.push val unless val in @tags
            @setTags @tags
            @input.val ''
            @refresh()
            TagsView.autocomplete.refresh('', @tags)
            TagsView.autocomplete.position()
            e.preventDefault()
            e.stopPropagation()
            return

        if e.keyCode in [188, 32, 9, 13]
            e.preventDefault()
            e.stopPropagation()
            return

        #UP, DOWN
        if e.keyCode in [40, 38]
            return true

        if val and e.keyCode isnt 8
            @refreshAutocomplete()
            return true

    refreshAutocomplete: (e) =>
        if @input.val() isnt ''
            TagsView.autocomplete.$el.show()

        return if e?.keyCode in [40, 38, 8]
        TagsView.autocomplete.refresh @input.val(), @tags

    tagClicked: (e) ->
        tag = e.target.dataset.value
        # simulate search
        $("#search-box").val("tag:#{tag}").trigger 'keyup'


    setTags: (newTags) =>
        @tags = newTags
        @tags ?= []
        @refresh()
        clearTimeout @saveLater
        @saveLater = setTimeout =>
            @model.save tags: @tags
        , 1000 # 3s

    deleteTag: (e) =>
        tag = e.target.parentNode.dataset.value
        @setTags _.without @tags, tag
        e.stopPropagation()
        e.preventDefault()

    afterRender: ->
        @refresh()
        @tags = @model.get('tags')
        @input = @$('input')

    refresh: =>
        @$('.tag').remove()
        html = ("""
                <li class="tag" data-value="#{tag}">
                    #{tag}
                    <span class="deleter fa fa-times"></span>
                </li>
            """ for tag in @tags or []).join ''
        @$el.prepend html

    toggleInput: =>
        @$('input').toggle()
        @$('input').focus() if @$('input').is(':visible')

    hideInput: =>
        @$('input').hide()

TagsView.autocomplete = new Autocomplete(id: 'tagsAutocomplete')
TagsView.autocomplete.render()
