americano = require 'americano-cozy'
ContactLog = require './contact_log'

module.exports = Contact = americano.getModel 'Contact',
    id            : String
    fn            : String # vCard FullName = display name
    n             : String # vCard Name = splitted
    # (Familly;Given;Middle;Prefix;Suffix)
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

Contact::getComputedFN = (config) ->
    [familly, given, middle, prefix, suffix] = @n.split ';'
    config ?= {}
    config.nameOrder ?= 'given-familly'
    switch config.nameOrder
        when 'given-familly' then "#{given} #{middle} #{familly}"
        when 'familly-given' then "#{familly}, #{given} #{middle}"
        when 'given-middleinitial-familly'
            "#{given} #{initial(middle)} #{familly}"

Contact::toVCF = (config) ->

    model = @toJSON()

    out = "BEGIN:VCARD\n"
    out += "VERSION:3.0\n"
    out += "NOTE:#{model.note}\n" if model.note

    if model.n
        out += "N:#{model.n}\n"
        out += "FN:#{@getComputedFN(config)}\n"
    else if model.fn
        out += "N:;;;;\n"
        out += "FN:#{model.fn}\n"
    else
        out += "N:;;;;\n"
        out += "FN:\n"

    for i, dp of model.datapoints

        value = dp.value

        key = dp.name.toUpperCase()
        switch key

            when 'ABOUT'
                if dp.type is 'org' or dp.type is 'title'
                    out += "#{dp.type.toUpperCase()}:#{value}\n"
                else
                    out += "X-#{dp.type.toUpperCase()}:#{value}\n"

            when 'OTHER'
                out += "X-#{dp.type.toUpperCase()}:#{value}\n"

            when 'ADR'
                # since a proper address management would be very complicated
                # we trick it a bit so it matched the standard
                value = value.replace /(\r\n|\n\r|\r|\n)/g, ";"
                content = "TYPE=home,postal:;;#{value};;;;"
                out += "ADR;#{content}\n"
            else
                type = "TYPE=#{dp.type.toUpperCase()}"
                out += "#{key};#{type}:#{value}\n"

    out += "END:VCARD\n"
