PhoneCommunicationLog = require '../models/phone_communication_log'
async   = require 'async'

module.exports =

    # send all logs for the req.contact
    byContact: (req, res) ->
        keys = req.contact.remoteKeys()
        ContactLog.byRemote keys, (err, logs) ->
            return res.error err if err
            res.send logs, 200

    # create a note-typed log (manual)
    create: (req, res) ->
        data =
            type: 'NOTE'
            direction: 'NA'
            timestamp: new Date(req.body.timestamp).toISOString()
            remote: id: req.contact.id
            content: req.body.content

        ContactLog.create data, (err, log) ->
            return res.error err if err
            res.send log, 201

    # merge a batch of voice typed log
    # exported from the phone
    merge: (req, res) ->
        ContactLog.merge req.body, (err) ->
            return res.error err if err
            res.send success: true, 201

    # merge voice & sms typed log from carrier's invoice
    mergeFing: (req, res) ->
        PhoneCommunicationLog.all (finglogs) ->
            return res.error err if err

            # convert to ContactLog Doctype
            finglogs = finglogs.map (log) ->
                log = log.toJSON()
                log.remote = tel: log.correspondantNumber
                if log.type is 'VOICE'
                    log.content = duration: log.chipCount

                return log

            ContactLog.merge finglogs, (err) ->
                return res.error err if err
                res.send success: true, 201

