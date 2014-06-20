FileCollection = require './collections/files'
UploadQueue = require './collections/upload_queue'
File = require './models/file'
SocketListener = require '../lib/socket'
FolderView = require './views/folder'

###
Initialize the model and start the actual code
###
module.exports =

    initialize: ->

        # the base collection holds all the files and folders of the application
        @baseCollection = new FileCollection()

        # queue to allow new uploads while uploading
        @uploadQueue = new UploadQueue()

        @socket = new SocketListener()
        @socket.watch @baseCollection

        Router = require 'router'
        @router = new Router()

        # Generate the root folder
        @root = new File
            id: "root"
            path: ""
            name: t 'root folder name'
            type: "folder"
        @baseCollection.add @root

        # for easy debugging in browser (and dirty tricks)
        window.app = @

        Backbone.history.start()

        # Makes this object immuable.
        Object.freeze this if typeof Object.freeze is 'function'
