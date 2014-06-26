localization = require './lib/localization_manager'
RealtimeAdapter = require 'cozy-realtime-adapter'
File = require './models/file'
Folder = require './models/folder'
feed = require './lib/feed'
init = require './helpers/init'

module.exports.beforeStart = (callback) ->
    localization.initialize callback

module.exports.afterStart = (app, server, callback) ->
    
    feed.initialize server

    # retrieve locale and set polyglot object
    # notification events should be proxied to client
    realtime = RealtimeAdapter server: server, ['file.*', 'folder.*', 'contact.*']
    init.updateIndex()    

    updateIndex = (type, id)->
        type.find id, (err, file) =>
            if err 
                return console.log err.stack if err
            file.index ['name'], (err) ->
                if err 
                    return console.log err.stack if err
                else 
                    return

    realtime.on 'file.create', (event, id) ->
        updateIndex(File,id)
    realtime.on 'folder.create', (event, id) ->
        updateIndex(Folder, id)
    realtime.on 'file.update', (event, id) ->
        updateIndex(File, id)
    realtime.on 'folder.update', (event, id) ->
        updateIndex(Folder, id)

    callback app, server if callback?
