Contact = require '../models/contact'
Config = require '../models/config'
Todolist = require '../models/todolist'
Task = require '../models/task'
path    = require 'path'
multiparty = require 'multiparty'

module.exports =


    fetch: (req, res, next, id) ->
        Contact.find id, (err, contact) ->
            return res.error 500, 'An error occured', err if err
            return res.error 404, 'Contact not found' if not contact

            req.contact = contact
            next()

    list: (req, res) ->
        Contact.request 'all', (err, contacts) ->
            return res.error 500, 'An error occured', err if err
            res.send contacts

    create: (req, res) ->

        # support both JSON and multipart for upload
        model = if req.body.contact then JSON.parse req.body.contact
        else req.body

        toCreate = new Contact model

        create = ->
            Contact.create toCreate, (err, contact) ->
                if err
                    next err
                else
                    res.send contact, 201

        if model.import
            # If creation is related to an import, it checks first if the
            # contact doesn't exist already by comparing the names
            # or emails if name is not specified.
            Config.getInstance (err, config) ->
                name = ''
                if toCreate.fn? and toCreate.fn.length > 0
                    name = toCreate.fn
                else if toCreate.n and toCreate.n.length > 0
                    name = toCreate.n.split(';').join(' ').trim()
                else
                    for dp in toCreate.datapoints
                        if dp.name is 'email'
                            name = dp.value

                Contact.request 'byName', key: name, (err, contacts) ->
                    if contacts.length is 0
                        create()
                    else
                        res.send contacts[0], 201
        else
            create()

    read: (req, res) ->
        res.send req.contact

    update: (req, res) ->
        model = if req.body.contact then JSON.parse req.body.contact
        else req.body

        req.contact.updateAttributes model, (err) ->
            if err
                return res.error 500, "Update failed.", err
            else
                res.send req.contact, 201

    # Extract and save picture in a temporary folder, then save it to data
    # system and delete it from disk.
    updatePicture: (req, res, next) ->
        form = new multiparty.Form()
        form.parse req, (err, fields, files) ->
            if err
                next err
            else if files? and files.picture? and files.picture.length > 0
                file = files.picture[0]
                req.contact.savePicture file.path, (err) ->
                    if err
                        next err
                    else
                        res.send req.contact, 201
            else
                next new Error 'Can\'t change picture, no file is attached.'

    delete: (req, res) ->
        req.contact.destroy (err) ->
            return res.error 500, "Deletion failed.", err if err

            res.send "Deletion succeded.", 204

    picture: (req, res, next) ->
        if req.contact._attachments?.picture
            stream = req.contact.getFile 'picture', (err) ->
                next err if err

            stream.pipe res
        else
            res.sendfile path.resolve __dirname, '../assets/defaultpicture.png'

    # Export contacts to a vcard file.
    vCard: (req, res, next) ->
        Config.getInstance (err, config) ->
            Contact.request 'all', (err, contacts) ->
                next err if err

                out = ""
                out += contact.toVCF(config) for contact in contacts

                date = new Date()
                date = "#{date.getYear()}-#{date.getMonth()}-#{date.getDate()}"
                res.attachment "cozy-contacts-#{date}.vcf"
                res.set 'Content-Type', 'text/x-vcard'
                res.send out

    # Export a single contact to a VCard file.
    vCardContact: (req, res, next) ->
        Config.getInstance (err, config) ->
            Contact.request 'all', key: req.params.contactid, (err, contacts) ->
                next err if err

                out = ""
                out += contact.toVCF(config) for contact in contacts

                date = new Date()
                date = "#{date.getYear()}-#{date.getMonth()}-#{date.getDate()}"
                res.attachment "#{req.params.fn}.vcf"
                res.set 'Content-Type', 'text/x-vcard'
                res.send out
