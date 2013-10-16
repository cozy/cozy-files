PhoneCommunicationLog = require '../models/phone_communication_log'
async   = require 'async'

module.exports =

    byContact: (req, res) ->
        out = []
        async.eachSeries req.contact.phoneNumbers(), (number, callback) ->
            PhoneCommunicationLog.byNumber number, (err, logs) ->
                logs.forEach (log) -> out.push log
                callback()
        , (err) ->
            return res.error err if err
            res.send out, 200

    merge: (req, res) ->
        newlogs = req.body.map PhoneCommunicationLog.prepareItem
        PhoneCommunicationLog.bySnippet (err, oldlogs) ->
            return res.error err if err

            # keep only new logs
            newlogs = newlogs.filter (log) -> not oldlogs[log.snippet]?

            async.eachSeries newlogs, (log, cb) ->
                PhoneCommunicationLog.create log, cb
            , (err) ->
                return res.error err if err
                res.send success: 'created', 201
