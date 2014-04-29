File = require '../models/file'
Folder = require '../models/folder'
CozyInstance = require '../models/cozy_instance'
clearance = require 'cozy-clearance'
async = require 'async'
jade = require 'jade'
fs = require 'fs'
NotificationHelper = require 'cozy-notifications-helper'

try CozyAdapter = require('americano-cozy/node_modules/jugglingdb-cozy-adapter')
catch e then CozyAdapter = require('jugglingdb-cozy-adapter')

cozydomain = 'http://your.friends.cozy.url/'
CozyInstance.getURL (err, domain) =>
    return console.log err if err
    cozydomain = domain

notifications = new NotificationHelper 'files'

publicURL = (doc) ->
    if doc instanceof File
        "#{cozydomain}public/files/files/#{doc.id}"
    else if doc instanceof Folder
        "#{cozydomain}public/files/folder/#{doc.id}"
    else throw new Error('wrong usage')

# helpers functions to handle inherited clearance

# give the viewable path above folder
module.exports.limitedTree = (folder, req, perm, callback) ->

    if typeof perm is "function"
        callback = perm
        perm = 'r'

    folder.getParents (err, parents) ->
        return callback err if err

        # remove start of path until first visible
        scan = ->
            tested = parents[0]
            return callback [] unless tested
            clearance.check tested, perm, req, (err, authorized) ->
                return callback [] if err
                if not authorized
                    parents.shift()
                    scan()
                else
                    callback parents, authorized
        scan()

# check that doc is viewable by req
# doc is visible iff any of itself or its parents is viewable
module.exports.checkClearance = (doc, req, perm, callback)  ->

    if typeof perm is "function"
        callback = perm
        perm = 'r'

    checkAscendantVisible = ->
        module.exports.limitedTree doc, req, perm, (results, rule) ->
            callback results.length isnt 0, rule

    if doc.constructor is File
        clearance.check doc, perm, req, (err, result) ->
            if result # the file itself is visible
                callback true
            else
                checkAscendantVisible()
    else
        checkAscendantVisible()

# notify guests of file change, if they want it
# this is 5min-throttled to avoid multiple mails for one batch change
# <File> file : the file that has changed
# <Bool> publicRequest is this a guest action
# callback
mailsToSend = {}
timer = null
_5min = 5000 # 5 * 60 * 1000
module.exports.notifyChanges = (who, file, callback) ->
    clearTimeout timer if timer

    file.getParents (err, parents) ->
        return callback err if err
        for folder in parents when folder.clearance?.length
            for rule in folder.clearance
                if rule.email isnt who and rule.notifications
                    timer = setTimeout doSendNotif, _5min
                    uniq = rule.key + folder.name
                    mailsToSend[uniq] =
                        name: folder.name
                        url: publicURL(folder) + '&key=' + rule.key
                        to: rule.email

            if who isnt 'owner' and folder.changeNotification
                uniq = 'udapte' + folder.id
                params =
                    text: "#{who} uploaded file #{file.name} into #{folder.name}"
                    resource:
                        app: 'files'
                        url: "#folder/#{folder.id}"

                notifications.createOrUpdatePersistent uniq, params, (err) ->
                    console.log err if err

        callback null

# send notif mails
templatefile = require('path').join __dirname, '../views/notifmail.jade'
notiftemplate = jade.compile fs.readFileSync templatefile, 'utf8'
doSendNotif = ->
    for key, item of mailsToSend

        mailOptions =
            to: item.to
            subject: "Cozy-file: #{item.name} has changed "
            content: item.url
            html: notiftemplate name: item.name, url: item.url

        CozyAdapter.sendMailFromUser mailOptions, (err) ->
            console.log 'sent update mail to ', item.to
            console.log err if err

    mailsToSend = {}