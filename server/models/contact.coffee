americano = require 'americano-cozy'
ContactLog = require './contact_log'

module.exports = Contact = americano.getModel 'Contact',
    id            : String
    fn            : String
    datapoints    : (x) -> x
    note          : String
    tags          : (x) -> x # DAMN IT JUGGLING
    _attachments  : Object

Contact::remoteKeys = ->
    model = @toJSON()
    out = [@id]
    for dp in model.datapoints
        if dp.name is 'tel'
            out.push ContactLog.normalizeNumber dp.value
        else if dp.name is 'email'
            out.push dp.value.toLowerCase()
    return out

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