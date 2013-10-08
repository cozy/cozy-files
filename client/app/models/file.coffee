client = require "../helpers/client"


module.exports = class Bookmark extends Backbone.Model

    # This field is required to know from where data should be loaded.
    # We'll cover it better in the backend part.
    rootUrl: 'files/'

    # use same events as backbone to enable socket-listener
    prepareCallbacks: (callbacks, presuccess, preerror) ->
        {success, error} = callbacks or {}
        presuccess ?= (data) => @set data.app
        @trigger 'request', @, null, callbacks
        callbacks.success = (data) =>
            presuccess data if presuccess
            @trigger 'sync', @, null, callbacks
            success data if success
        callbacks.error = (jqXHR) =>
            preerror jqXHR if preerror
            @trigger 'error', @, jqXHR, {}
            error jqXHR if error


    # Get application description
    getAttachment: (file, callbacks) ->
        @prepareCallbacks callbacks
        client.post "files/#{@id}/getAttachment/#{@name}", callbacks
