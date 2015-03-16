File = require '../models/file'
contactCollection = require 'cozy-clearance/contact_collection'


# Manage events coming from the Data System: remote operations on files.
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


    # When file is remotely created, add the file only if it's not already
    # there or if the file is not uploading.
    onRemoteCreate: (model) ->
        inCache = @isInCachedFolder model
        alreadyInFolder = @collection.isFileStored model

        # Prevent the create if the model is locally uploading because it loses
        # its mind otherwise.
        if inCache and not alreadyInFolder and not model.isUploading()
            @collection.add model, merge: true


    # When a remote deletion occurs, remote it from the current file list.
    onRemoteDelete: (model) ->
        if @isInCachedFolder model
            @collection.remove model


    # WHen an remote update occurs, it update the model if it's listed in the
    # current file list and if it's not uploading.
    onRemoteUpdate: (model, collection) ->
        inCache = @isInCachedFolder model
        alreadyInFolder = @collection.isFileStored model

        # Prevent the update if the model is locally uploading because it loses
        # its mind otherwise.
        if inCache and not alreadyInFolder and not model.isUploading()
            @collection.add model, merge: true


    # Apply remote operation to current list. Current list contains cache of
    # all loaded files. Full data are fetched before applying any modification.
    #
    # Update can lead to a creation when the upload flag is changed from
    # true to false. We don't apply creation until the upload is finished
    # (file metadata are created remotely before the upload starts).
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

                    if model? and not model.isUploading()
                        model.fetch
                            success: (fetched) =>
                                if fetched.changedAttributes()
                                    fetched.set type: doctype
                                    @onRemoteUpdate fetched, collection

            when 'delete'
                @collections.forEach (collection) =>
                    return unless model = collection.get id
                    @onRemoteDelete model, collection
