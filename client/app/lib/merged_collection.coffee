
# return a collection that behave as a merge of two collection
# if a model is present in both collection (by Id),
# model from collection A is favored

module.exports = MergedCollection = (a, b, uniqAttr='id') ->

    mixed = new Backbone.Collection [],
        comparator: a.comparator

    mixed.A = a
    mixed.B = b

    do reset = () ->
        models = []
        ids = []
        a.forEach (model) ->
            models.push model
            ids.push model.id
        b.forEach (model) ->
            models.push model unless model.id in ids

        mixed.reset models

    sameAs = (model, collection) ->
        search = {}
        search[uniqAttr] = model.get uniqAttr
        collection.findWhere(search)



    events =
        reset: => reset()

        remove: (model, collection) =>
            other = if collection is a then b else a
            mixed.remove model
            if model.id and existingOther = sameAs model, other
                mixed.add existingOther

        add: (model, collection) ->
            if existing = sameAs model, mixed
                if collection is a
                    mixed.remove existing
                    mixed.add model
                else
                    return #do nothing
            else
                mixed.add model

        'change:id': (model) ->
            dups = mixed.where(id: model.id)
            if dups.length is 2
                toRemove = if dups[0].collection is b then 0 else 1
                mixed.remove dups[toRemove]

        sort: ->
            mixed.sort()

    a.bind events
    b.bind events
    return mixed