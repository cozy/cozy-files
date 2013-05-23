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

    save: () ->
        @dataPoints.prune()
        super

    toJSON: () ->
        json = super
        json.datapoints = @dataPoints.toJSON()
        return json

