module.exports = class DataPointCollection extends Backbone.Collection

    model: require 'models/datapoint'

    hasOne: (type) ->
        @where(name: type).length > 0

    prune: () ->
        toDelete = []
        @each (datapoint) =>
            value = datapoint.get('value')
            if (value is null) or (value is '') or (value is ' ')
                toDelete.push datapoint

        @remove toDelete