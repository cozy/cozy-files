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

        # Check if model is located in current folder
        isLocatedInFolder = @isInCachedFolder model

        if isLocatedInFolder
            isAlreadyInFolder = @collection.isFileStored model
            isInQueue = @uploadQueue.isFileStored model
            isAlreadyInFolder = isAlreadyInFolder or isInQueue
            isUploading = model.get('uploading') or false

            if not(isAlreadyInFolder) and not(isUploading)
                @collection.add model, merge: true

    onRemoteDelete: (model) ->
        if @isInCachedFolder model
            @collection.remove model

    onRemoteUpdate: (model, collection) ->
        isUploading = model.get('uploading') or false
        if @isInCachedFolder(model) and not(isUploading)
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
                    model = collection.get id
                    if model?
                        model.fetch
                            success: (fetched) =>
                                if fetched.changedAttributes()
                                    fetched.set type: doctype
                                    @onRemoteUpdate fetched, collection
                    else
                        model = new @models[doctype](id: id, type: doctype)
                        model.fetch
                            success: (fetched) =>
                                # set as a folder or a file
                                fetched.set type: doctype
                                @onRemoteCreate fetched

            when 'delete'
                @collections.forEach (collection) =>
                    return unless model = collection.get id
                    @onRemoteDelete model, collection
