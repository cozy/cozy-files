db = require '../db/cozy-adapter'

module.exports = Contact = db.define 'Contact',
    id            : String
    fn            : String
    datapoints    : [Object]
    note          : String
    _attachments  : Object

Contact::toVCF = ->

    model = @toJSON()


    out = "BEGIN:VCARD\n"
    out += "VERSION:3.0\n"
    out += "NOTE:#{model.note}\n" if model.note
    out += "FN:#{model.fn}\n"


    for i, dp of model.datapoints

        value = dp.value

        switch dp.name

            when 'about'
                if dp.type is 'org' or dp.type is 'title'
                    out += "#{dp.type.toUpperCase()}:#{value}\n"
                else
                    out += "X-#{dp.type.toUpperCase()}:#{value}\n"

            when 'other'
                out += "X-#{dp.type.toUpperCase()}:#{value}\n"

            else
                key = dp.name.toUpperCase()
                value = value.replace(/(\r\n|\n\r|\r|\n)/g, ";") if key is 'ADR'
                type = "TYPE=#{dp.type.toUpperCase()}"
                out += "#{key};#{type}:#{value}\n"


    out += "END:VCARD\n"