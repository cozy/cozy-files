BaseView = require 'lib/base_view'

module.exports = class DataPointView extends BaseView

    template: require 'templates/datapoint'

    tagName: 'li'
    className: 'datapoint'

    events: ->
        'blur .type'   : 'store'
        'blur .value'  : 'store'
        'keyup .type'  : 'onKeyup'
        'keyup .value' : 'onKeyup'
        'keypress .value' : 'onValueKeyPress'
        'keypress .type' : 'onTypeKeyPress'
        'click .dpremove': 'removeModel'

    getRenderData: ->
        _.extend @model.toJSON(), placeholder: @getPlaceHolder()

    afterRender: ->
        @valuefield = @$('.value')
        @typefield  = @$('input.type')
        @actionLink = @$('.dpaction')
        @typefield.typeahead source: @getPossibleTypes
        @makeActionLink()

    getPossibleTypes: =>
        # TODO : replace me with something smart, like most often used
        # TODO : i18n ...
        switch @model.get 'name'
            when 'about' then ['org', 'birthday', 'title']
            when 'other' then ['skype', 'jabber', 'irc']
            when 'url'   then ['facebook', 'google', 'website']
            else ['main', 'home', 'work', 'assistant']

    getPlaceHolder: ->
        switch @model.get 'name'
            when 'email' then 'john.smith@example.com'
            when 'adr' then '42 main street ...'
            when 'tel' then '+33 1 23 45 67 89'
            when 'url' then 'http://example.com/john-smith'
            when 'about', 'other' then t 'type here'

    makeActionLink: ->
        action = (icon, title, href, noblank) =>
            @$el.append @actionLink unless @actionLink.parent()
            @actionLink.attr {title, href}
            if noblank then @actionLink.removeAttr 'target'
            else @actionLink.attr 'target', '_blank'
            @actionLink.find('i').addClass 'icon-' + icon

        value = @model.get 'value'
        switch @model.get 'name'
            when 'email'
                action 'envelope', 'send mail', "mailto:#{value}", true
            when 'tel'
                href = @callProtocol() + ':+' + value
                action 'headphones', 'call', href, true
            when 'url'
                action 'share', 'go to this url', "#{value}", false
            when 'other'
                if @model.get('type') is 'skype'
                    action 'headphones', 'call', "callto:#{value}"
            else @actionLink.detach()

    callProtocol: ->
        if navigator.userAgent.match(/(mobile)/gi) then 'tel'
        else 'callto'

    onKeyup: (event) =>
        empty = $(event.target).val().length is 0
        backspace = (event.which or event.keyCode) is 8

        unless backspace
            @secondBack = false
            return true

        unless empty
            return true

        if @secondBack then =>
            prev = @$el.prev('li').find('.value')
            @removeModel()
            prev.focus().select() if prev

        else @secondBack = true

    removeModel: ->
        @model.collection.remove @model

    store: ->
        @model.set
            value: @valuefield.val()
            type: @typefield.val()

    # Put the focus on the previous visible input when user press tab on a type
    # field.
    # If there are no more datapoint, it focus the tagit field.
    onTypeKeyPress: (event) ->
        keyCode = event.keyCode
        keyCode ?= event.which
        if keyCode is 9 # 9 is tab code.
            if event.shiftKey
                prev = @$el.prev()

                if prev.length is 0
                    prev = @$el.parent().parent()
                    prev = prev.prev()

                    while not prev.is(':visible') and prev.length > 0
                        prev = prev.prev()

                    if prev.length is 0
                        prev = $ ".ui-widget-content"
                    else
                        prev = prev.find '.value'
                else
                    prev = prev.find '.value'

                prev.focus()
                prev.select()
            else
                $(event.target).next().focus()

            event.preventDefault()
            false
        else
            true

    # Put the focus on the next visible input when user press tab on a value
    # field.
    # If there are no more datapoint, it focus the note textarea.
    onValueKeyPress: (event) ->
        keyCode = event.keyCode
        keyCode ?= event.which

        if keyCode is 9 # 9 is tab code.
            if event.shiftKey
                $(event.target).prev().focus()
            else
                next = @$el.next()
                if next.length is 0
                    next = @$el.parent().parent()
                    next = next.next()

                    while not next.is(':visible') and next.attr('id')?
                        next = next.next()

                    if not next.attr('id')?
                        next = $ "textarea#notes"
                    else
                        next = next.find '.type'
                else
                    next = next.find('.type')

                next.focus()
                next.select()

            event.preventDefault()
            false
        else
            true
