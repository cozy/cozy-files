Contact = require '../models/contact'
path    = require 'path'
fs      = require 'fs'

module.exports = (app) ->

    fetch: (req, res, next, id) ->
        Contact.find id, (err, contact) ->
            return res.error 500, 'An error occured', err if err
            return res.error 404, 'Contact not found' if not contact

            req.contact = contact
            next()

    list: (req, res) ->
        Contact.request 'all', (err, albums) ->
            return res.error 500, 'An error occured', err if err
            res.send albums

    create: (req, res) ->

        # support both JSON and multipart for upload
        model = if req.body.contact then JSON.parse req.body.contact
        else req.body

        toCreate = new Contact model
        Contact.create toCreate, (err, contact) ->
            return res.error 500, "Creation failed.", err if err

            if file = req.files?['picture']
                data = name: 'picture', type: file.type
                contact.attachFile file.path, data, (err) ->
                    return res.error 500, "Creation failed.", err if err

                    fs.unlink file.path, (err) ->
                        return res.error 500, "Creation failed.", err if err

                        res.send contact, 201
            else
                res.send contact, 201


    read: (req, res) ->
        res.send req.contact

    update: (req, res) ->

        # support both JSON and multipart for upload
        model = if req.body.contact then JSON.parse req.body.contact
        else req.body

        req.contact.updateAttributes model, (err) ->
            return res.error 500, "Update failed.", err if err

            if file = req.files?['picture']
                data = name: 'picture', type: file.type
                req.contact.attachFile file.path, data, (err) ->
                    return res.error 500, "Update failed.", err if err

                    fs.unlink file.path, (err) ->
                        console.log "failed to purge #{file.path}"

                        res.send req.contact, 201
            else
                res.send req.contact, 201

    delete: (req, res) ->
        req.contact.destroy (err) ->
            return res.error 500, "Deletion failed.", err if err

            res.send "Deletion succeded.", 204

    picture: (req, res) ->
        if req.contact._attachments?.picture
            stream = req.contact.getFile 'picture', (err) ->
                return res.error 500, "File fetching failed.", err if err

            stream.pipe res
        else
            res.sendfile path.resolve __dirname, '../assets/defaultpicture.png'

    vCard: (req, res) ->
        Contact.request 'all', (err, contacts) ->
            return res.error 500, 'An error occured', err if err

            out = ""
            out += contact.toVCF() for contact in contacts

            date = new Date()
            date = "#{date.getYear()}-#{date.getMonth()}-#{date.getDate()}"
            res.attachment "cozy-contacts-#{date}.vcf"
            res.set 'Content-Type', 'text/x-vcard'
            res.send out



