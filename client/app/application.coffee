FileCollection = require './collections/files'
UploadQueue = require './collections/upload_queue'
File = require './models/file'
SocketListener = require '../lib/socket'
FolderView = require './views/folder'
client = require './lib/client'

###
Initialize the model and start the actual code
###
module.exports =

    initialize: ->

        # if the application is browsed by a guest or not
        # we use that in various places of the application (as few as possible)
        @isPublic = window.location.pathname.indexOf('/public/') is 0

        # the base collection holds all the files and folders of the application
        @baseCollection = new FileCollection()

        # queue to allow new uploads while uploading
        @uploadQueue = new UploadQueue @baseCollection

        @socket = new SocketListener()
        @socket.watch @baseCollection

        Router = require 'router'
        @router = new Router()

        # Generate the root folder
        # In shared area there are more properties because the root is an
        # actual folder
        if window.rootFolder?
            @root = new File window.rootFolder
            @root.canUpload = window.canUpload or false
            @root.publicNotificationsEnabled = window.publicNofications or false
            @root.publicKey = window.publicKey or ""
        else
            # Fake folder to describe the root
            @root = new File
                id: "root"
                path: ""
                name: t 'root folder name'
                type: "folder"
        @baseCollection.add @root

        # for easy debugging in browser (and dirty tricks)
        client.get 'publicUrl', (err, body) =>
            if err?
                url = "#{window.location.origin}/public/files/"
            else
                url = body.url
            @domain = url
            window.app = @

            Backbone.history.start()

            # Makes this object immuable.
            Object.freeze this if typeof Object.freeze is 'function'

