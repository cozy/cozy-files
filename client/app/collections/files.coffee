File = require '../models/file'

module.exports = class FileCollection extends Backbone.Collection

    # Model that will be contained inside the collection.
    model: File

    # sort
    order: "asc"

    # This is where ajax requests the backend.
    url: 'files'

    # patch Model.sync so it could trigger progress event
    sync: (method, model, options)->
        progress = (e)->
            model.trigger('progress', e)

        _.extend options,
            xhr: ()->
                xhr = $.ajaxSettings.xhr()
                if xhr instanceof window.XMLHttpRequest
                    xhr.addEventListener 'progress', progress, false
                if xhr.upload
                    xhr.upload.addEventListener 'progress', progress, false
                xhr

        Backbone.sync.apply @, arguments

    

    # sorting - folders first, then alphabetically, by name
    comparator: (o1, o2) ->

        n1 = o1.get("name").toLocaleLowerCase()
        n2 = o2.get("name").toLocaleLowerCase()

        t1 = o1.get("isFolder")
        t2 = o2.get("isFolder")

        sort = if @order == "asc" then -1 else 1

        if t1 == t2
            if n1 > n2 then return -sort
            if n1 < n2 then return sort
            return 0
        else if t1
            return -1
        else
            return 1