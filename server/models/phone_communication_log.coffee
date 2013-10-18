americano = require 'americano-cozy'
async = require 'async'

# This is the FING communication log doctype
PhoneCommunicationLog = americano.getModel 'PhoneCommunicationLog',
    origin              : type: String, default: 'cozy-contacts'
    direction           : String
    timestamp           : String
    correspondantNumber : String
    chipCount           : Number
    chipType            : String
    type                : String
    snippet             : String


PhoneCommunicationLog.byNumber = (number, callback) ->
    options = key : PhoneCommunicationLog.normalizeNumber number
    PhoneCommunicationLog.request 'byNumber', options, callback

# for realtime
PhoneCommunicationLog.deduplicate = (event, id) ->
    PhoneCommunicationLog.find id, (err, log) ->
        if err or not log?.snippet
            return console.log "[Dedup] could not found doc id=", id, err, log

        if log.origin isnt 'Orange'
            return null # not orange, not pb

        snippet = log.snippet

        PhoneCommunicationLog.request 'bySnippet', key:snippet, (err, items) ->
            if err
                return console.log "[Dedup]", snippet, "err = ", err

            if items.length < 2
                return console.log "[Dedup]", snippet, "no dup"

            async.each items, (item, cb) ->
                # we keep the one from Orange
                if item.origin is 'Orange' then cb null
                else item.destroy cb
            , (err) ->
                if err
                    return console.log "[Dedup]", snippet, " fail=", err
                else
                    console.log "[Dedup]", snippet, " success"

# for initialization
PhoneCommunicationLog.removeDuplicates = (callback) ->
    PhoneCommunicationLog.request 'bySnippet', (err, items) ->
        return callback err if err
        index = {}
        toDelete = []
        for item in items

            duplicate = index[item.snippet]

            # pick a survivor
            if duplicate?.origin is "Orange"
                toDelete.push item
            else if duplicate
                toDelete.push duplicate
            else
                index[item.snippet] = item

        async.each toDelete, (item, cb) ->
            item.destroy cb
        , callback


module.exports = PhoneCommunicationLog