BaseView = require '../lib/base_view'

module.exports = class Autocomplete extends BaseView

    className: 'autocomplete'
    tagName: 'ul'

    events: ->
        'click li': 'onClick'

    onInputKeyDown: (e) =>
        if e.keyCode in [38, 40] # UP & DOWN
            delta = e.keyCode - 39
            @select @selectedIndex + delta
            e.preventDefault()
            e.stopPropagation()

    onClick: (e) ->
        @input.val e.target.dataset.value

        # pretend we press enter
        event = $.Event('keydown')
        event.keyCode = 13 #enter
        @input.trigger event
        e.preventDefault()
        e.stopPropagation()
        $target = @$target
        @unbindCancel = true
        @input.parents('.folder-row').addClass 'pseudohover'
        @input.focus()


    initialize: ->
        @tags = window.tags.map (value, idx) ->
            el = document.createElement('li')
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

        @visible = @tags.filter (tag) ->
            tag.value not in existings and tag.lc? and
            ~tag.lc.indexOf search.toLowerCase()

        if selected and selected in @visible
            @selectedIndex = @visible.indexOf selected
        else
            @selectedIndex = -1

        @$el.empty().append _.pluck @visible, 'el'

    select: (index) ->

        for tag in @tags
            tag.el.classList.remove 'selected'

        index = (index + @visible.length) % @visible.length

        @selectedIndex = index
        @visible[@selectedIndex].el.classList.add 'selected'
        @input.val @visible[@selectedIndex].value

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
        @input.val('')
        @$target = null
        @$el.hide()
        @$el.detach()
        @selectedIndex = -1
