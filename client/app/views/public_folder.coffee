FolderView = require './folder'
client = require '../lib/client'

module.exports = class PublicFolderView extends FolderView

    events: _.extend FolderView::events, 'click #notifications': 'onToggleNotificationClicked'


    initialize: (options) ->
        super options
        @rootFolder = options.rootFolder

    afterRender: ->
        super()

        # we use those class to show/hide stuff via CSS (buttons, controls, etc.)
        classes = ' public'
        classes += ' can-upload' if @rootFolder.canUpload
        @$el.addClass classes

    getRenderData: ->
        _.extend super(),
            isPublic: true
            areNotificationsEnabled: @rootFolder.publicNotificationsEnabled
            hasPublicKey: @rootFolder.publicKey.length > 0

    # Enable or disable guest notifications
    onToggleNotificationClicked: ->

        # Notifications are only handled for the root folder
        key = window.location.search
        url = "#{@model.urlRoot()}#{@rootFolder.id}/notifications#{key}"

        # toggle notifications button and persist state in database
        if @rootFolder.publicNotificationsEnabled
            @rootFolder.publicNotificationsEnabled = false
            @$('#notifications').html '&nbsp;'
            @$('#notifications').spin 'tiny'
            client.put url, notificationsState: false, (err) =>
                @$('#notifications').spin false
                unless err?
                    @$('#notifications').html t 'notifications disabled'
                    @$('#notifications').removeClass 'toggled'
        else
            @rootFolder.publicNotificationsEnabled = true
            @$('#notifications').html '&nbsp;'
            @$('#notifications').spin 'tiny'
            client.put url, notificationsState: true, (err) =>
                @$('#notifications').spin false
                unless err?
                    @$('#notifications').html t 'notifications enabled'
                    @$('#notifications').addClass 'toggled'