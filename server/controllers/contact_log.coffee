ContactLog = require '../models/contact_log'
async   = require 'async'

module.exports =

    # send all logs for the req.contact
    byContact: (req, res) ->
        keys = req.contact.remoteKeys()
        ContactLog.byRemote keys, (err, logs) ->
            # logs = logs.toJSON()
            # HACKY : todo, figure out a way to do this in couch
            logs.sort (x, y) ->
                tx = new Date(x.timestamp).getTime()
                ty = new Date(y.timestamp).getTime()
                return 1 if tx > ty
                return -1 if tx < ty
                # tx = ty, NOTES last
                return 1 if x.type is 'NOTE' and y.type isnt 'NOTE'
                return -1 if y.type is 'NOTE' and x.type isnt 'NOTE'
                return 0

            return res.error err if err
            res.send logs, 200

    fetch: (req, res, next, id) ->
        ContactLog.find id, (err, log) ->
            return res.error 500, 'An error occured', err if err
            return res.error 404, 'Log not found' if not log

            req.log = log
            next()

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

    update: (req, res) ->
        req.log.updateAttributes req.body, (err) ->
            return res.error err if err
            res.send req.log, 200


    delete: (req, res) ->
        req.log.destroy (err) ->
            return res.error err if err
            res.send success: true, 204


    # merge a batch of voice typed log
    # exported from the phone
    merge: (req, res) ->
        toMerge = if Array.isArray req.body then req.body else [req.body]
        ContactLog.merge toMerge, (err) ->
            return res.error err if err
            res.send success: true, 201

    # merge voice & sms typed log from carrier's invoice
    mergeFing: (req, res) ->
        PhoneCommunicationLog.all (finglogs) ->
            return res.error err if err

            # convert to ContactLog Doctype
            converted = finglogs.map (log) ->
                log = log.toJSON()
                log.remote = tel: log.correspondantNumber
                if log.type is 'VOICE'
                    log.content = duration: log.chipCount

                return log

            ContactLog.merge converted, (err) ->
                return res.error err if err
                res.send success: true, 201

