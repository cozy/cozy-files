contact = require './contact'

module.exports =


    'widget':
        get: contact.widget

    'contactid':
        param: contact.fetch

    'contacts.vcf':
        get: contact.vCard

    'contacts':
        get: contact.list
        post: contact.create

    'contacts/:contactid':
        get: contact.read
        put: contact.update
        del: contact.delete

    'contacts/:contactid/picture.png':
        get: contact.picture

    '':
        get: contact.index