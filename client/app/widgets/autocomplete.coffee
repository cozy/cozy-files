BaseView = require '../lib/base_view'

ENTER_KEY = 13
ARROW_UP_KEY = 38
ARROW_DOWN_KEY = 40

module.exports = class Autocomplete extends BaseView

    className: 'autocomplete'
    tagName: 'ul'

    events: ->
        'click li': 'onClick'

    onInputKeyDown: (e) =>
        if e.keyCode in [ARROW_UP_KEY, ARROW_DOWN_KEY]
            delta = e.keyCode - 39 # delta will be +/- 1
            @select @selectedIndex + delta
            e.preventDefault()
            e.stopPropagation()

    onClick: (e) ->
        @input.val e.target.dataset.value

        # pretend we press enter
        event = $.Event 'keydown'
        event.keyCode = ENTER_KEY
        @input.trigger event
        e.preventDefault()
        e.stopPropagation()
        @unbindCancel = true

        @input.parents('.folder-row').addClass 'pseudohover'
        @input.focus()


    initialize: (options = {}) ->

        # maximum number of tags to display in the list
        @limit = options.limit or 10

        window.tags ?= []
        @tags = window.tags.map (value, idx) ->
            el = document.createElement 'li'
            el.textContent = value
            el.dataset.value = value
            el.dataset.index = idx
            lc = value.toLowerCase()
            return {value, el, lc}

    position: ->
        pos = @input.offset()
        pos.top += @input.height() + 2
        pos.width = @input.width() + 2
        @$el.appendTo($('body')).css(pos).show()


    refresh: (search, existings) ->
        search = @input.val()
        selected = @visible?[@selectedIndex]
        existings ?= []

        for tag in @tags
            tag.el.classList.remove 'selected'

        @visible = @tags.filter (tag, index) =>
            return (tag.value not in existings) and tag.lc? and \
            ~tag.lc.indexOf(search.toLowerCase()) and \
            index < @limit

        if selected and selected in @visible
            @selectedIndex = @visible.indexOf selected
        else
            @selectedIndex = -1

        @$el.empty().append _.pluck @visible, 'el'

        # styles the list when it's empty
        @$el.toggleClass 'empty', @visible.length is 0

    select: (index) ->

        for tag in @tags
            tag.el.classList.remove 'selected'

        index = (index + @visible.length) % @visible.length

        @selectedIndex = index
        visibleElement = @visible[@selectedIndex]
        if visibleElement?
            visibleElement.el.classList.add 'selected'
            @input.val visibleElement.value

    bind: ($target) ->
        return if $target is @$target
        @unbind() if @$target
        @$target = $target
        @input = @$target.find 'input'
        @position()

        @input.on 'keydown', @onInputKeyDown
        @input.on 'blur', @delayedUnbind
        @selectedIndex = -1

    delayedUnbind: =>
        @unbindCancel = false
        clearTimeout @delayedUnbindTimeout if @delayedUnbindTimeout
        @delayedUnbindTimeout = setTimeout @unbind, 100

    unbind: =>
        return if @unbindCancel or not @input
        @input.off 'keydown', @onInputKeyDown
        @input.off 'blur', @delayedUnbind
        @input.parents('.folder-row').removeClass 'pseudohover'
        @input.val ''
        @$target = null
        @$el.hide()
        @$el.detach()
        @selectedIndex = -1
