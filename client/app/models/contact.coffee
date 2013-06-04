DataPointCollection = require 'collections/datapoint'

# A contact
# Properties :
# - dataPoints : a PhotoCollection of the photo in this album
# maintains attribute
module.exports = class Contact extends Backbone.Model

    urlRoot: 'contacts'

    constructor: ->
        @dataPoints = new DataPointCollection()
        super

    defaults: ->
        name: ''
        notes: ''

    parse: (attrs) ->
        if attrs.datapoints
            @dataPoints.reset attrs.datapoints
            delete attrs.datapoints
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
                @trigger 'change', this, {}
                delete @picture

        super(method, model, options)

    match: (filter) =>
        filter.test(@get('name')) or
        filter.test(@get('notes')) or
        @dataPoints.match filter

    toJSON: () ->
        json = super
        json.datapoints = @dataPoints.toJSON()
        delete json.picture
        return json

