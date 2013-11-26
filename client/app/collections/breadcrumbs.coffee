File = require '../models/file'

module.exports = class BreadcrumbsManager extends Backbone.Collection

    model: File

    # we only want to add models in a certain order
    add: (folder) ->
        super folder, sort: false

    # when adding a folder
    push: (folder)->
        if @get folder
            
            found = false
            treatment = (model, callback) ->
                if not found
                    if model.id == folder.id then found = true
                    callback null, [model]
                else
                    callback null

            async.concatSeries @models, treatment, (err, folders) =>
                if err
                    console.log err
                else
                    @reset folders, sort: false
        else
            @add folder, sort: false

    setRoot: (root) ->
        @reset()
        @root = root
        @add root

    popAll: ->
        @setRoot @root
