BaseView = require 'lib/base_view'

module.exports = class HistoryItemView extends BaseView

    template: require 'templates/history_item'

    tagName: 'tr'
    className: ->
        'history_item ' + if @isAnnotable() then 'annotable'

    events:
        'blur .editor'     : 'save'
        'click .notedelete': 'delete'

    getRenderData: ->
        directionIcon: @getDirectionIcon()
        typeIcon: @getTypeIcon()
        details : @getDetails()
        date: @model.get 'timestamp'

    afterRender: ->
        @editor = @$('.editor')
        if @model.get('type') is 'NOTE'
            @editor.val @model.get 'content'
            @editor.focus()
        else
            @editor.remove()
            @$('.details').text @getDetails()

    isAnnotable: -> 'NOTE' isnt @model.get 'type'

    save: ->
        @model.save content: @editor.val()

    delete: ->
        @model.destroy()

    getDirectionIcon: ->
        switch @model.get 'direction'
            when 'INCOMING' then 'icon-forward'
            when 'OUTGOING' then 'icon-backward'
            else false

    getTypeIcon: ->
        switch @model.get 'type'
            when 'VOICE' then 'icon-headphones'
            when 'MAIL'  then 'icon-enveloppe'
            when 'SMS'   then 'icon-list-alt'
            when 'NOTE'  then 'icon-edit'
            else 'icon-stop'

    getDetails: ->
        details = @model.get 'content'
        switch @model.get 'type'
            when 'VOICE'
                t('duration') + ' : ' + details.duration
            when 'SMS' then details.message
            when 'NOTE' then details
            else '???'



