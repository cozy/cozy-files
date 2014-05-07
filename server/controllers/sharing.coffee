File = require '../models/file'
Folder = require '../models/folder'
User = require '../models/user'
helpers = require '../helpers/sharing'
clearance = require 'cozy-clearance'
async = require 'async'

localization = require '../lib/localization_manager'

templatefile = require('path').join __dirname, '../views/sharemail.jade'
mailTemplate = notiftemplate = localization.getEmailTemplate 'sharemail.jade'

clearanceCtl = clearance.controller
    mailTemplate: (options, callback) ->
        options.type = options.doc.docType.toLowerCase()
        User.getDisplayName (err, displayName) ->
            options.displayName = displayName or localization.t 'default user name'
            options.localized_type = localization.t options.type
            options.localized_link = localization.t "link #{options.type} content"
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
    Folder.all (err, folders) =>
        return callback err if err

        # only look at parents
        fullPath = req.doc.getFullPath()
        parents = folders.filter (tested) ->
            fullPath.indexOf(tested.getFullPath()) is 0 and
            fullPath isnt tested.getFullPath()

        # sort them in path order
        parents.sort (a,b) ->
            a.getFullPath().length - b.getFullPath().length

        results = parents.map (parent) ->
            name: parent.path + '/' + parent.name
            clearance: parent.clearance or []

        # keep only element of path that alter the clearance
        isPublic = false
        inherited = results?.filter (x) ->
            if isPublic then return false

            isPublic = true if x.clearance is 'public'
            return x.clearance.length isnt 0

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
