BaseView = require '../lib/base_view'
Modal = require "./modal"
client = require "../helpers/client"
CozyClearanceModal = require "cozy-clearance/modal_share_view"

module.exports = class ModalShareView extends CozyClearanceModal

    events: -> _.extend super,
        'click #inherited-share-summary a': =>
            @$('#inherited-share-list').show()
            @$('#inherited-share-summary').hide()

    initialize: (options) ->
        @type = @model.get('type')
        super
        @summaryemails = []
        client.get "share/#{@type}/#{@model.id}",
            error: => Modal.error 'server error occured', => @$el.modal 'hide'
            success: (data) =>
                @inherited = data.inherited

                last = _.last @inherited
                if last?.clearance is 'public'
                    @forcedPublic = last.name

                # acutally render content
                @refresh()

    typeaheadFilter: (item) =>
        email = item.toString().split(';')[0]
        super and email not in @summaryemails

    getRenderData: ->
        clearance = if @forcedPublic then 'public' else @model.get('clearance')
        _.extend super, {clearance}

    afterRender: () ->
        super

        if @forcedPublic
            text = t('forced public') + @forcedPublic
            @$('#share-private').hide().after $('<p>').text text
        else
            listitems = []
            summary = []

            for folder in @inherited when folder.clearance.length isnt 0
                text = t('inherited from') + folder.name
                listitems.push $('<li>').addClass('header').text text
                for rule in folder.clearance
                    summary.push rule.email
                    listitems.push $('<li>').text rule.email

            if summary.length isnt 0
                @summaryemails = summary
                text = t('also have access') + ' : ' + summary.join(', ') + '. '
                summary = $('<div id="inherited-share-summary">').text text
                summary.append $('<a>').text t('details')
                list = $('<ul id="inherited-share-list">').hide()
                list.append item for item in listitems
                @$('#share-list').after summary, list

    doSave: (sendmail, newClearances) =>
        client.put "share/#{@type}/#{@model.id}", clearance: @model.get('clearance'),
            error: -> ModalView.error 'server error occured'
            success: (data) =>
                if not sendmail
                    @$el.modal 'hide'
                else
                    client.post "share/#{@type}/#{@model.id}/send", newClearances,
                        error: -> ModalView.error 'mail not send'
                        success: (data) =>
                            @$el.modal 'hide'