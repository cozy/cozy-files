module.exports = (app) ->
    contact = require('./controllers/contact')(app)

    # fetch on params
    app.param 'contactid',                                    contact.fetch

    # CRUD routes
    app.get   '/contacts/?',                                  contact.list
    app.get   '/contacts.vcf',                                contact.vCard
    app.post  '/contacts/?',                                  contact.create
    app.get   '/contacts/:contactid/?',                       contact.read
    app.put   '/contacts/:contactid/?',                       contact.update
    app.del   '/contacts/:contactid/?',                       contact.delete

    app.get   '/contacts/:contactid/picture.png',             contact.picture
