jade = require 'jade'
fs = require 'fs'

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
            @templates.link = jade.compile jadeString


    sendPublicLink: (file, callback) ->
        # get the domain
        CozyInstance.getURL (err, domain) =>
            if err
                console.log err.stack
                return callback err
            else
                url = "#{domain}/public/cozy-files/file#{file.id}"

                mailOptions =
                    from: "Cozy<cozy@cozy.io>"
                    subject: "Cozy-file: your shared file link"
                    content: url # TODO - see if this is necessary
                    html: @templates.link
                        file: file
                        url: url

                CozyAdapter.sendMailToUser mailOptions, (err) ->
                    if err
                        console.log err
                        callback err, url
                    else
                        callback null, url
