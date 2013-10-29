BaseView = require 'lib/base_view'

module.exports = class HistoryItemView extends BaseView

    template: require 'templates/history_item'

    className: ->
        console.log 'HERE'
        classes = ['history_item']
        classes.push @model.get('direction').toLowerCase()
        classes.push @model.get('type').toLowerCase()
        classes.push 'annotable' if @isAnnotable()
        return classes.join ' '

    events:
        'blur .editor'     : 'save'
        'click .notedelete': 'delete'

    getRenderData: ->
        format = '{Mon} {d}, {h}:{m} : '

        return {
            typeIcon: @getTypeIcon()
            content : @getContent()
            date: Date.create(@model.get('timestamp')).format format
        }

    isAnnotable: ->
        @model.get('type') is 'VOICE'

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
            when 'VOICE' then 'icon-voice'
            when 'MAIL'  then 'icon-mail'
            when 'SMS'   then 'icon-sms'
            else 'icon-stop'

    getContent: ->
        details = @model.get 'content'
        switch @model.get 'type'
            when 'VOICE'
                t('duration') + ' : ' + @formatDuration details.duration
            when 'SMS' then details.message
            else '???'

    formatDuration: (duration) ->
        seconds = (duration % 60)
        minutes = (duration - seconds) % 3600
        hours = (duration - minutes - seconds)

        out = seconds + t('seconds')
        out = minutes/60 + t('minutes') + ' ' + out if minutes
        out = hours/3600 + t('hours') + ' ' + out if hours
        return out





