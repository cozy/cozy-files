module.exports = class DataPointCollection extends Backbone.Collection

    model: require 'models/datapoint'

    hasOne: (name, type) ->
        query = name: name
        query.type = type if type
        return @where(query).length > 0

    toJSON: ->
        truedps = this.filter (model) ->
            value = model.get('value')
            (value isnt null) and (value isnt '') and (value isnt ' ')

        return truedps.map (model) -> model.toJSON()

    prune: () ->
        toDelete = []
        @each (datapoint) =>
            value = datapoint.get('value')
            if (value is null) or (value is '') or (value is ' ')
                toDelete.push datapoint

        @remove toDelete

    match: (filter) ->
        @any (datapoint) -> filter.test datapoint.get('value')