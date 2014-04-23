File = require '../models/file'
Folder = require '../models/folder'
helpers = require '../helpers/sharing'
clearance = require 'cozy-clearance'
async = require 'async'
jade = require 'jade'
fs = require 'fs'

templatefile = require('path').join __dirname, '../views/sharemail.jade'
mailTemplate = jade.compile fs.readFileSync templatefile, 'utf8'

clearanceCtl = clearance.controller
    mailTemplate: (options) ->
        options.type = options.doc.docType.toLowerCase()
        mailTemplate options
    mailSubject: (options) ->
        type = options.doc.docType.toLowerCase()
        "Cozy-file: someone has shared a #{type} with you"

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
            err = new Error('bad usage')
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
            isPublic = true if x.clearance is 'public'
            return isPublic or x.clearance.length isnt 0

        res.send inherited: inherited

# expose clearanceCtl functions
module.exports.change = clearanceCtl.change

module.exports.sendAll = clearanceCtl.sendAll

module.exports.contactList = clearanceCtl.contactList