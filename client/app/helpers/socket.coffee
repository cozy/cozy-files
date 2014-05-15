File = require '../models/file'

module.exports = class SocketListener extends CozySocketListener

    models:
        'file'   : File
        'folder' : File

    events: [
        'file.create'
        'file.update'
        'file.delete'
        'folder.create'
        'folder.update'
        'folder.delete'
    ]

    isInCurrentFolder: (model) ->
        cwd = app.folderView.model.repository()
        mwd = model.get "path"
        mwd is cwd

    onRemoteCreate: (model) ->
        if @isInCurrentFolder model
            console.log "remote create"
            console.log model
            if not (@collection.get model.get("id"))
                @collection.add model, merge:true

    onRemoteDelete: (model) ->
        if @isInCurrentFolder model
            console.log "remote delete"
            console.log model
            @collection.remove model

    onRemoteUpdate: (model, collection) ->
        if @isInCurrentFolder model
            console.log "remote update"
            console.log model
            collection.add model, merge:true

    process: (event) ->
        {doctype, operation, id} = event

        # console.log "received: #{operation}:#{doctype}"

        switch operation
            when 'create'
                model = new @models[doctype](id: id, type: doctype)
                model.fetch
                    success: (fetched) =>
                        # set as a folder or a file
                        fetched.set type: doctype
                        @onRemoteCreate fetched

            when 'update'
                @collections.forEach (collection) =>
                    return unless model = collection.get id
                    model.fetch
                        success: (fetched) =>
                            if fetched.changedAttributes()
                                fetched.set type: doctype
                                @onRemoteUpdate fetched, collection

            when 'delete'
                @collections.forEach (collection) =>
                    return unless model = collection.get id
                    @onRemoteDelete model, collection
