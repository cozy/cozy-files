File = require '../models/file'
client = require "../helpers/client"

module.exports = class BreadcrumbsManager extends Backbone.Collection

    model: File

    # we only want to add models in a certain order
    add: (folder) ->
        super folder, sort: false

    # when adding a folder
    push: (folder) ->

        # expanding the first node in case of direct access:
        #   - only root on the stack
        #   - isn't just the first folder (empty path)
        #   - isn't root (on init)
        #   - isn't search
        if (@length is 1) and (@at(0) is @root) and (folder isnt @root) and (folder.get("path") isnt "") and (folder.get("type") is "folder")

            path = folder.get("path").split("/")
            path = path.slice(1, path.length)

            client.get "folder/tree/" + folder.id, (err) ->
                if err
                    console.log "err", err
                else
                    @add data, sort: false
                    @add folder, sort: false


        else

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
