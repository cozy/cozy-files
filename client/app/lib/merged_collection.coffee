
# return a collection that behave as a merge of two collection
# if a model is present in both collection (by Id),
# model from collection A is favored

module.exports = MergedCollection = (primary, secondary, uniqAttr='id') ->

    mixed = new Backbone.Collection [],
        comparator: primary.comparator

    mixed.Primary = primary
    mixed.Secondary = secondary

    do reset = ->
        models = []
        ids = []
        primary.forEach (model) ->
            models.push model
            ids.push model.id
        secondary.forEach (model) ->
            models.push model unless model.id in ids

        mixed.reset models

    sameAs = (model, collection) ->
        search = {}
        search[uniqAttr] = model.get uniqAttr
        collection.findWhere search

    events =
        reset: reset

        remove: (model, collection) =>
            other = if collection is primary then secondary else primary
            mixed.remove model
            if model.id and existingOther = sameAs model, other
                mixed.add existingOther

        add: (model, collection) ->
            if existing = sameAs model, mixed
                # if the file is being put from secondary to main collection
                # or if the file is being overwritten
                if collection is primary or model.conflict
                    mixed.remove existing
                    mixed.add model
            else
                mixed.add model

        'change:id': (model) ->
            dups = mixed.where id: model.id
            if dups.length is 2
                toRemove = if dups[0].collection is secondary then 0 else 1
                mixed.remove dups[toRemove]

        sort: ->
            mixed.sort()

    primary.bind events
    secondary.bind events
    return mixed
