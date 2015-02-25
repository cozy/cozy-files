Folder = require '../models/folder'
File = require '../models/file'

sharing = require '../helpers/sharing'

module.exports.checkClearance = (permission, type) -> (req, res, next) ->
    if req.folder?
        element = new Folder req.folder
    else if req.file?
        element = new File req.file
    else if type is 'folder'
        element = new Folder req.body
    else
        element = new File req.body

    sharing.checkClearance element, req, permission, (authorized, rule) ->
        if authorized
            if rule?
                req.guestEmail = rule.email
                req.guestId = rule.contactid
            next()
        else
            err = new Error 'You cannot access this resource'
            err.status = 404
            err.template =
                name: '404'
                params:
                    localization: require '../lib/localization_manager'
                    isPublic: true
            next err
