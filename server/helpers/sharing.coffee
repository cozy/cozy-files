File = require '../models/file'
Folder = require '../models/folder'
clearance = require 'cozy-clearance'
async = require 'async'
jade = require 'jade'
fs = require 'fs'
try CozyAdapter = require('americano-cozy/node_modules/jugglingdb-cozy-adapter')
catch e then CozyAdapter = require('jugglingdb-cozy-adapter')

# helpers functions to handle inherited clearance

# give the viewable path above folder
module.exports.limitedTree = (folder, req, callback) ->
    Folder.all (err, folders) =>
        if err
            console.log err
            return callback []

        # only look at parents
        fullPath = folder.getFullPath()
        parents = folders.filter (tested) ->
            fullPath.indexOf(tested.getFullPath()) is 0

        # sort them in path order
        parents.sort (a,b) ->
            a.getFullPath().length - b.getFullPath().length

        # remove start of path until first visible
        scan = ->
            tested = parents[0]
            return callback [] unless tested
            clearance.check tested, 'r', req, (err, authorized) ->
                return callback [] if err
                if not authorized
                    parents.shift()
                    scan()
                else
                    callback parents
        scan()

# check that doc is viewable by req
# doc is visible iff any of itself or its parents is viewable
module.exports.checkClearance = (doc, req, callback)  ->

    checkAscendantVisible = ->
        module.exports.limitedTree doc, req, (results) ->
            callback results.length isnt 0

    if doc.constructor is File
        clearance.check doc, 'r', req, (err, result) ->
            if result # the file itself is visible
                callback true
            else
                checkAscendantVisible()
    else
        checkAscendantVisible()

# send a share mail
templatefile = require('path').join __dirname, '../views/sharemail.jade'
mailtemplate = jade.compile fs.readFileSync templatefile, 'utf8'
module.exports.sendMail = (type, doc, key, cb) ->
    rule = doc.clearance.filter((rule) -> rule.key is key)[0]
    doc.getPublicURL (err, url) =>
        return cb err if err

        url += '?key=' + key

        mailOptions =
            to: rule.email
            subject: "Cozy-file: someone has shared a #{type} with you"
            content: url
            html: mailtemplate(name: doc.name, url: url, type: type)

        CozyAdapter.sendMailFromUser mailOptions, (err) ->
            if err
                console.log err
                cb err
            else
                cb null