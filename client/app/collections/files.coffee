File = require '../models/file'

module.exports = class FileCollection extends Backbone.Collection

    # Model that will be contained inside the collection.
    model: File

    # sort
    order: "incr"
    type: "name"

    # This is where ajax requests the backend.
    url: 'files'


    comparator: (o1, o2) ->

        if @type is "name"
            n1 = o1.get("name").toLocaleLowerCase()
            n2 = o2.get("name").toLocaleLowerCase()
        else if @type is "lastModification"
            n1 = new Date(o1.get("lastModification"))
            n2 = new Date(o2.get("lastModification"))
        else
            n1 = o1.get(@type)
            n2 = o2.get(@type)

        t1 = o1.get("type")
        t2 = o2.get("type")

        sort = if @order == "incr" then -1 else 1

        if t1 is t2
            if n1 > n2 then return -sort
            if n1 < n2 then return sort
            return 0
        else if t1 is "file"
            return -sort
        else
            return sort