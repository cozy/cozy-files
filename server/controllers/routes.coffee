contact = require './contact'
callLog = require './call_log'

module.exports =

    '':
        get: contact.index

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

    'contacts/:contactid/logs':
        get:  callLog.byContact
        post: callLog.create

    'logs':
        post: callLog.merge
