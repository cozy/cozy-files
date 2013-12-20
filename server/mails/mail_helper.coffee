jade = require 'jade'
fs = require 'fs'
async = require 'async'

CozyInstance = require '../models/cozy_instance'
try CozyAdapter = require('americano-cozy/node_modules/jugglingdb-cozy-adapter')
catch e then CozyAdapter = require('jugglingdb-cozy-adapter')

module.exports = class MailHandler

    constructor: () ->
        @templates = {}

        # prepare the template
        file = __dirname + '/file_public.jade'
        fs.readFile file, 'utf8', (err, jadeString) =>
            throw err if err
            @templates.file = jade.compile jadeString
        folder = __dirname + '/folder_public.jade'
        fs.readFile folder, 'utf8', (err, jadeString) =>
            throw err if err
            @templates.folder = jade.compile jadeString

    getFileUrl: (file, cb) ->
        CozyInstance.getURL (err, domain) =>
            if err
                cb err
            else
                # generate the url 
                domain = domain.replace("http://", "")
                cb null, "http://#{domain}/public/files/file#{file.id}"

    getFolderUrl: (folder, cb) ->
        CozyInstance.getURL (err, domain) =>
            if err
                cb err
            else
                # generate the url 
                domain = domain.replace("http://", "")
                cb null, "http://#{domain}/public/files/folder#{folder.id}"


    sendPublicFileLinks: (file, users, callback) ->

        @getFileUrl file, (err, url) =>
            if err
                console.log err.stack
                callback err
            else

                sendMail = (mail, cb) =>
                    mailOptions =
                        to: mail
                        subject: "Cozy-file: someone has shared a file with you"
                        content: url
                        html: @templates.file
                            file: file
                            url: url

                    CozyAdapter.sendMailFromUser mailOptions, (err) ->
                        if err
                            console.log err
                            cb err
                        else
                            cb null

                async.each users, sendMail, (err) ->
                    if err
                        callback err
                    else
                        callback null, url

    sendPublicFolderLinks: (folder, users, callback) ->

        @getFolderUrl folder, (err, url) =>
            if err
                console.log err.stack
                callback err
            else

                sendMail = (mail, cb) =>
                    mailOptions =
                        to: mail
                        subject: "Cozy-file: someone has shared a folder with you"
                        content: url
                        html: @templates.folder
                            folder: folder
                            url: url

                    CozyAdapter.sendMailFromUser mailOptions, (err) ->
                        if err
                            console.log err
                            cb err
                        else
                            cb null

                async.each users, sendMail, (err) ->
                    if err
                        callback err
                    else
                        callback null, url
