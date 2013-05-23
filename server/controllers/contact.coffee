Contact = require '../models/contact'
path = require 'path'

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
        contact = new Contact req.body
        Contact.create contact, (err, contact) ->
            return res.error 500, "Creation failed.", err if err

            res.send contact, 201

    read: (req, res) ->
        res.send req.contact

    update: (req, res) ->
        req.contact.updateAttributes req.body, (err) ->
            return res.error 500, "Update failed.", err if err

            res.send req.contact

    delete: (req, res) ->
        req.contact.destroy (err) ->
            return res.error 500, "Deletion failed.", err if err

            res.send "Deletion succeded.", 204

    picture: (req, res) ->
        if req.contact._attachments?.picture
            stream = req.contact.getFile 'picture', (err) ->
            if err then res.error 500, "File fetching failed.", err
            else stream.pipe res
        else
            res.sendfile path.resolve __dirname, '../assets/defaultpicture.png'
