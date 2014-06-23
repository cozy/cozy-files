window.CozySocketListener = {fake: ''}
FolderView = require './folder'
File = require '../models/file'
FilesView = require './files'
FileCollection = require '../collections/files'
Modal = require './modal'

class PublicFilesView extends FilesView
    initialize: (@collection, @model) ->
        # patch to not use socket listener
        FilesView.__super__.initialize.apply this, arguments

    # reload to re-render
    addItem: -> window.location.reload()

module.exports = class PublicFolderView extends FolderView

    el: document.getElementsByTagName('body')[0]
    templates: -> ''
    initialize: (options) ->
        @model = new File _.extend options.folder, type: 'folder'
        @uploadQueue = options.uploadQueue
        # patch to use proper url
        old = File::urlRoot
        File::urlRoot = -> '../' + old.apply(this, arguments) + window.location.search

        # patch to allow uploads
        @collection = new FileCollection []
        @filesList = new PublicFilesView @collection, @model
        @$('#download-link').click (event) ->
            if window.numElements is 0
                event.preventDefault()
                Modal.error t 'modal error zip empty folder'

    onCancelFolder: ->
        # this feels hacky, but not sure how to handle it better
        # there has been some uploading done, let's reload
        super
        if @$('.progress-name').length
            window.location.reload()
