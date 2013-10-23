BaseView = require 'lib/base_view'

module.exports = class DataPointView extends BaseView

    template: require 'templates/datapoint'

    tagName: 'li'
    className: 'datapoint'

    events: ->
        'blur .type'     : 'store'
        'blur .value'    : 'store'
        'keyup .type'  : 'onKeyup'
        'keyup .value' : 'onKeyup'
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
                action 'headphones', 'call', "tel:#{value}", true
            when 'url'
                action 'share', 'go to this url', "#{value}"
            else @actionLink.detach()


    onKeyup: (event) ->
        empty = $(event.target).val().length is 0
        backspace = (event.which or event.keyCode) is 8

        unless backspace
            @secondBack = false
            return true

        unless empty
            return true

        if @secondBack then @removeModel()

        else @secondBack = true

    removeModel: ->
        prev = @$el.prev('li').find('.value')
        @model.collection.remove @model
        prev.focus().select() if prev

    store: ->
        @model.set
            value: @valuefield.val()
            type: @typefield.val()
