File = require '../models/file'
Folder = require '../models/folder'
User = require '../models/user'
helpers = require '../helpers/sharing'
clearance = require 'cozy-clearance'
async = require 'async'

localization = require '../lib/localization_manager'

templatefile = require('path').join __dirname, '../views/sharemail.jade'
mailTemplate = notiftemplate = localization.getEmailTemplate 'sharemail.jade'

CozyInstance = require("cozydb").api.CozyInstance

clearanceCtl = clearance.controller
    mailTemplate: (options, callback) ->
        options.type = options.doc.docType.toLowerCase()
        User.getDisplayName (err, displayName) ->
            options.displayName = displayName or \
                                  localization.t 'default user name'

            options.localization = localization
            callback null, mailTemplate options

    mailSubject: (options, callback) ->
        type = options.doc.docType.toLowerCase()
        name = options.doc.name
        User.getDisplayName (err, displayName) ->
            displayName = displayName or localization.t 'default user name'
            callback null, localization.t 'email sharing subject',
                                displayName: displayName
                                name: name

# fetch file or folder, put it in req.doc
module.exports.fetch = (req, res, next, id) ->
    async.parallel [
        (cb) -> File.find id, (err, file) -> cb null, file
        (cb) -> Folder.find id, (err, folder) -> cb null, folder
    ], (err, results) ->
        [file, folder] = results
        doc = file or folder
        if doc
            req.doc = doc
            next()
        else
            err = new Error 'bad usage'
            err.status = 400
            next err

# retrieve inherited sharing info
module.exports.details = (req, res, next) ->
    req.doc.getInheritedClearance (err, inherited) ->
        if err? then next err
        else
            res.send inherited: inherited

# do not use clearanceCtl, because we handle notifications
module.exports.change = (req, res, next) ->

    {clearance, changeNotification} = req.body
    body = {clearance, changeNotification}

    req.doc.updateAttributes body, (err) ->
        return next err if err
        res.send req.doc

# expose clearanceCtl functions
module.exports.sendAll = clearanceCtl.sendAll

module.exports.contactList = clearanceCtl.contactList

module.exports.contactPicture = clearanceCtl.contactPicture

module.exports.contact = clearanceCtl.contact

