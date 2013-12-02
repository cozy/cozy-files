File = require '../models/file'

module.exports = class SocketListener extends CozySocketListener

    models:
        'file': File
        'folder': File

    events: [
        'file.create'
        'file.update'
        'file.delete'
        'folders.create'
        'folder.update'
        'folder.delete'
    ]

    onRemoteCreate: (model) ->
        console.log "create: "
        console.log model

    onRemoteDelete: (model) ->
        console.log "delete: "
        console.log model

    # process: (event) ->
    #     console.log "socket.process: #{event}"
    #     {doctype, operation, id} = event
    #     switch operation
    #         when 'create'
    #             model = new @models[doctype](id: id, type: doctype)
    #             model.fetch
    #                 success: (fetched) =>
    #                     @onRemoteCreate fetched

    #         when 'update'
    #             if model = @singlemodels.get id
    #                 model.fetch
    #                     success: (fetched) =>
    #                         if fetched.changedAttributes()
    #                             @onRemoteUpdate fetched, null

    #             @collections.forEach (collection) =>
    #                 return unless model = collection.get id
    #                 model.fetch
    #                     success: (fetched) =>
    #                         if fetched.changedAttributes()
    #                             @onRemoteUpdate fetched, collection

    #         when 'delete'
    #             if model = @singlemodels.get id
    #                 @onRemoteDelete model, @singlemodels

    #             @collections.forEach (collection) =>
    #                 return unless model = collection.get id
    #                 @onRemoteDelete model, collection
