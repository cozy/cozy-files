files = require './files'
folders = require './folders'

module.exports =

    'files':
        get: files.all
        post: files.create
    'files/:id':
        get: files.find
        patch: files.modify
        delete: files.destroy
    'files/:id/attach/:name':
        get: files.getAttachment
    'files/:id/download/:name':
        get: files.downloadAttachment

    'folders':
        post: folders.create
    'folders/:id':
        get: folders.find
        patch: folders.modify
        delete: folders.destroy

    'folders/files':
        post: folders.findFiles
    'folders/folders':
        post: folders.findFolders

    'search/folders':
        post: folders.search
    'search/files':
        post: files.search
