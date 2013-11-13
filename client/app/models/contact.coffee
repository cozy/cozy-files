DataPoint = require 'models/datapoint'
DataPointCollection  = require 'collections/datapoint'
ContactLogCollection = require 'collections/contactlog'

ANDROID_RELATION_TYPES = ['custom', 'assistant', 'brother', 'child',
            'domestic partner', 'father', 'friend', 'manager', 'mother',
            'parent', 'partner', 'referred by', 'relative', 'sister', 'spouse']

# A contact
# Properties :
# - dataPoints : a PhotoCollection of the photo in this album
# maintains attribute
module.exports = class Contact extends Backbone.Model

    urlRoot: 'contacts'

    constructor: ->
        @dataPoints = new DataPointCollection()
        super

    initialize: ->
        @on 'change:datapoints', =>
            dps = @get 'datapoints'
            if dps
                @dataPoints.reset dps
                @set 'datapoints', null

        @history = new ContactLogCollection
        @history.url = @url() + '/logs'
        @on 'change:id', =>
            @history.url = @url() + '/logs'

    defaults: ->
        fn: ''
        note: ''
        tags: []

    parse: (attrs) ->
        if attrs.datapoints
            @dataPoints.reset attrs.datapoints
            delete attrs.datapoints

        if attrs._attachments?.picture
            @hasPicture = true
            delete attrs._attachments

        if attrs.n and not Array.isArray attrs.n
            attrs.n = attrs.n.split ';'

        return attrs

    sync: (method, model, options) ->
        if @picture
            options.contentType = false
            options.data = new FormData()
            options.data.append 'picture', @picture
            options.data.append 'contact', JSON.stringify @toJSON()
            success = options.success
            options.success = (resp) =>
                success resp
                @hasPicture = true
                @trigger 'change', this, {}
                delete @picture

        super(method, model, options)

    getBest: (name) ->
        result = null
        @dataPoints.each (dp) ->
            if dp.get('name') is name
                if dp.get('pref') then result = dp.get 'value'
                else result ?= dp.get 'value'

        return result


    addDP: (name, type, value)=>
        @dataPoints.add
            type: type
            name: name
            value: value

    match: (filter) =>
        filter.test(@get('fn')) or
        filter.test(@get('note')) or
        filter.test(@get('tags').join ' ') or
        @dataPoints.match filter

    toJSON: () ->
        json = super
        json.datapoints = @dataPoints.toJSON()
        json.n = json.n.join ';'
        delete json.picture
        return json


AndroidToDP = (contact, raw) ->
    parts = raw.split ';'
    switch parts[0].replace 'vnd.android.cursor.item/', ''
        when 'contact_event'
            value = parts[1]
            type = if parts[2] in ['0', '2'] then parts[3]
            else if parts[2] is '1' then 'anniversary'
            else 'birthday'
            contact.addDP 'about', type, value
        when 'relation'
            # console.log parts
            value = parts[1]
            type = ANDROID_RELATION_TYPES[+parts[2]]
            # console.log type
            type = parts[3] if type is 'custom'
            contact.addDP 'other', type, value

Contact.fromVCF = (vcf) ->

    # inspired by https://github.com/mattt/vcard.js

    regexps =
        begin:       /^BEGIN:VCARD$/i
        end:         /^END:VCARD$/i
        simple:      /^(version|fn|n|title|org|note)\:(.+)$/i
        android:     /^x-android-custom\:(.+)$/i
        composedkey: /^item(\d{1,2})\.([^\:]+):(.+)$/
        complex:     /^([^\:\;]+);([^\:]+)\:(.+)$/
        property:    /^(.+)=(.+)$/

    ContactCollection   = require 'collections/contact'
    imported = new ContactCollection()
    currentversion = "3.0"

    current = null
    currentidx = null
    currentdp = null

    for line in vcf.split /\r?\n/

        if regexps.begin.test line
            current = new Contact()

        else if regexps.end.test line
            current.dataPoints.add currentdp if currentdp
            imported.add current
            currentdp = null
            current = null
            currentidx = null
            currentversion = "3.0"

        else if regexps.simple.test line
            [all, key, value] = line.match regexps.simple

            key = key.toLowerCase()

            switch key
                when 'version' then currentversion = value
                when 'title', 'org'
                    current.addDP 'about', key, value
                when 'fn', 'note'
                    current.set key, value
                when 'n'
                    current.set key, value.split ';'
                when 'bday'
                    current.addDP 'about', 'birthday', value

        else if regexps.android.test line
                [all, value] = line.match regexps.android
                # console.log 'androd', value
                AndroidToDP current, value

        else if regexps.composedkey.test line
            [all, itemidx, part, value] = line.match regexps.composedkey

            if currentidx is null or currentidx isnt itemidx
                current.dataPoints.add currentdp if currentdp
                currentdp = new DataPoint()

            currentidx = itemidx

            part = part.split ';'
            key = part[0]
            properties = part.splice 1

            value = value.split(';')
            value = value[0] if value.length is 1

            key = key.toLowerCase()

            if key is 'x-ablabel' or key is 'x-abadr'
                value = value.replace '_$!<', ''
                value = value.replace '>!$_', ''
                currentdp.set 'type', value.toLowerCase()
            else
                for property in properties
                    [all, pname, pvalue] = property.match regexps.property
                    currentdp.set pname.toLowerCase(), pvalue.toLowerCase()

                if key is 'adr'
                    value = value.join("\n").replace /\n+/g, "\n"

                if key is 'x-abdate'
                    key = 'about'

                if key is 'x-abrelatednames'
                    key = 'other'

                currentdp.set 'name', key.toLowerCase()
                currentdp.set 'value', value.replace "\\:", ":"

        else if regexps.complex.test line
            [all, key, properties, value] = line.match regexps.complex

            current.dataPoints.add currentdp if currentdp
            currentdp = new DataPoint()

            # console.log all, '-->', key, properties, value

            value = value.split(';')
            value = value[0] if value.length is 1

            key = key.toLowerCase()

            if key in ['email', 'tel', 'adr', 'url']
                currentdp.set 'name', key
                if key is 'adr'
                    value = value.join("\n").replace /\n+/g, "\n"
            else
                currentdp = null
                continue

            properties = properties.split ';'

            # console.log "properties=", properties

            for property in properties
                match = property.match regexps.property
                if match then [all, pname, pvalue] = match
                else
                    pname = 'type'
                    pvalue = property

                if pname is 'type' and pvalue is 'pref'
                    currentdp.set 'pref', 1
                else
                    currentdp.set pname.toLowerCase(), pvalue.toLowerCase()

            currentdp.set 'value', value


    return imported