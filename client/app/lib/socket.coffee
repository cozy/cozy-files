File = require '../models/file'
contactCollection = require 'cozy-clearance/contact_collection'

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
        'contact.create'
        'contact.update'
        'contact.delete'
    ]

    # Check if the model is located in the currently displayed path
    isInCachedFolder: (model) ->
        path = model.get 'path'
        return @collection.isPathCached path

    onRemoteCreate: (model) ->
        console.log 'onRemoteCreate'

        # Check if model is located in current folder
        isLocatedInFolder = @isInCachedFolder model
        isAlreadyInFolder = @collection.isFileStored model

        if isLocatedInFolder and not isAlreadyInFolder
            @collection.add model, merge: true

    onRemoteDelete: (model) ->
        if @isInCachedFolder model
            # console.info "remote delete", model
            @collection.remove model

    onRemoteUpdate: (model, collection) ->
        if @isInCachedFolder model
            # console.info "remote update", model
            collection.add model, merge: true

    process: (event) ->
        {doctype, operation, id} = event

        if doctype is 'contact'
            contactCollection.handleRealtimeContactEvent event

        else switch operation
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
