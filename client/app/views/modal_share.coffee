BaseView = require '../lib/base_view'
Modal = require "./modal"
client = require "../helpers/client"
CozyClearanceModal = require "cozy-clearance/modal_share_view"

# extends the cozy-clearance modal to files specifics
module.exports = class ModalShareView extends CozyClearanceModal

    # display inherited details on summary's click
    events: -> _.extend super,
        'click #inherited-share-summary a': =>
            @$('#inherited-share-list').show()
            @$('#inherited-share-summary').hide()

    # retrieve inherited rules
    initialize: (options) ->
        @type = @model.get('type')
        super
        @summaryemails = []
        client.get "clearance/#{@model.id}",
            error: => Modal.error 'server error occured', => @$el.modal 'hide'
            success: (data) =>
                @inherited = data.inherited

                last = _.last @inherited
                if last?.clearance is 'public'
                    @forcedPublic = last.name

                # actually render content
                @refresh()

    # allow rw permissions for folder, customize message depending on type
    permissions: ->
        if @type is 'folder'
            'r': t 'perm r folder'
            'rw': t 'perm rw folder'
        else
            'r': t 'perm r file'

    # do not allow adding permissions for user who already have them by inheritance
    typeaheadFilter: (item) =>
        email = item.toString().split(';')[0]
        super and email not in @summaryemails

    # force 'public' display if forced public by inheritance
    getRenderData: ->
        out = super
        out.clearance = 'public' if @forcedPublic
        return out

    # ignore click on 'public' button when forced public by inheritance
    makePublic: ->
        return if @forcedPublic
        super

    # support forced public by inheritance and add inherited summary
    afterRender: () ->
        super

        if @forcedPublic
            text = t('forced public') + @forcedPublic
            @$('#share-public').addClass 'toggled'
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
                console.log summary, list
                @$('#share-list').after summary, list
        console.debug @model
        # if there is a writing guest
        guestCanWrite = _.findWhere @model.get('clearance'), perm: 'rw'
        if guestCanWrite
            checkbox = $('<input id="notifs" type="checkbox">')
            checkbox.prop 'checked', @model.get 'changeNotification'
            text = t('change notif')
            html = '<label class="notifs-label" for="notifs">'
            label = $(html).append checkbox, text
            @$('#share-list').after label


    # include the changes notification in PUT request
    saveData: ->
        changeNotification = @$('#notifs').prop('checked') or false
        _.extend super, changeNotification: changeNotification
