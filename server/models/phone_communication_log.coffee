americano = require 'americano-cozy'
async = require 'async'

ContactLog = require './contact_log'

# This is the FING communication log doctype
PCLog = americano.getModel 'PhoneCommunicationLog',
    origin              : type: String, default: 'cozy-contacts'
    direction           : String
    timestamp           : String
    correspondantNumber : String
    chipCount           : Number
    chipType            : String
    type                : String
    snippet             : String


PCLog.byNumber = (number, callback) ->
    options = key : PCLog.normalizeNumber number
    PCLog.request 'byNumber', options, callback

# for realtime
PCLog.mergeToContactLogRT = (event, id) ->
    PCLog.find id, (err, log) ->
        if err or not log?.snippet
            return console.log "[Dup] could not found doc id=", id, err, log

        converted = PCLog.toContactLog log
        ContactLog.merge [converted], (err) ->
            console.log err if err

# for initialization
PCLog.mergeToContactLog = (callback) ->
    PCLog.request 'bySnippet', (err, logs) ->
        return callback err if err

        converted = logs.map PCLog.toContactLog
        ContactLog.merge converted, (callback)

PCLog.toContactLog = (finglog) ->
    out =
        timestamp: finglog.timestamp
        direction: finglog.direction
        remote: tel: finglog.correspondantNumber
        type: finglog.type
        snippet: finglog.snippet

    if out.type is 'VOICE'
        out.content = duration: finglog.chipCount

    return out

module.exports = PCLog