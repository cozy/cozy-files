americano = require 'americano-cozy'

Mail = americano.getModel 'Mail',
     createdAt: type: Number, default: 0
     dateValueOf: type: Number, default: 0
     date: type: Date, default: 0
     from: type: String
     cc: type: String
     text: type: String
     html: type: String
     flags: type:  Object
     read: type:  Boolean, default: false
     flagged: type:  Boolean, default: false
     hasAttachments: type:  Boolean, default: false

MailSent = americano.getModel 'MailSent',
     createdAt: type:  Number, default: 0
     sentAt: type:  Number, default: 0
     subject: type: String
     from: type: String
     to: type: String
     cc: type: String
     bcc: type: String
     html: type: String
