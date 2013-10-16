PhoneCommunicationLog = require './server/models/phone_communication_log'
Realtimer = require 'cozy-realtime-adapter'

start = (port, callback) ->
    require('americano').start
            name: 'Contacts'
            port: port
    , (app, server) ->
        app.set 'views', './client/'

        # run patch to fix old contacts
        patch1 = require './server/patches/patch1'
        patch1 (err) ->
            return callback? err if err

            # FING ONLY
            # remove duplicates call log that might have appears
            # while app was down
            PhoneCommunicationLog.removeDuplicates (err) ->
                return callback? err if err

                # make client realtime
                realtime = Realtimer server: server, ['contact.*']

                # FING ONLY remove duplicates call log when they appears
                realtime.on 'phonecommunicationlog.create', \
                    PhoneCommunicationLog.deduplicate

                callback? null, app, server

if not module.parent
    port = process.env.PORT or 9114
    start port, (err) ->
        if err
            console.log "Initialization failed, not starting"
            console.log err.stack
            process.exit 1

else
    module.exports = start
