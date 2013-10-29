PhoneCommunicationLog = require '../models/phone_communication_log'
Realtimer = require 'cozy-realtime-adapter'

module.exports = (server, next) ->

    # Create ContactLog for FING Log that might
    # have appears while app was down
    PhoneCommunicationLog.mergeToContactLog (err) ->
        return next err if err

        # make client realtime
        realtime = Realtimer server: server, ['contact.*', 'callLog.*']

        # create ContactLog when FING Log appears
        realtime.on 'phonecommunicationlog.create', \
            PhoneCommunicationLog.mergeToContactLogRT

        next null