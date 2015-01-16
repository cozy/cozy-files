cozydb = require 'cozydb'

module.exports = CozyInstance = cozydb.getModel 'CozyInstance',
    id:     type: String
    domain: type: String
    locale: type: String

CozyInstance.getURL = (callback) ->
    CozyInstance.first (err, instance) ->
        if err then callback err
        else if instance?.domain
            url = instance.domain
            .replace('http://', '')
            .replace('https://', '')
            callback null, "https://#{url}/"
        else
            callback new Error 'No instance domain set'

CozyInstance.getLocale = (callback) ->
    CozyInstance.first (err, instance) ->
        callback err, instance?.locale or 'en'
