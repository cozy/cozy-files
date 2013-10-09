files = require './files'
folders = require './folders'
remotes = require './remotes'

module.exports =
    'files':
        get: files.all
        post: files.create
    'files/:id':
        get: files.find
        delete: files.destroy
    'files/:id/attach/:name':
        get: files.getAttachment
    'folders':
        post: folders.create
    'folders/:id':
        get: folders.find
        delete: folders.destroy
    'folders/root/files':
        get: folders.findFilesRoot
    'folders/root/folders':
        get: folders.findFoldersRoot
    'folders/:id/files':
        get: folders.findFiles
    'folders/:id/folders':
        get: folders.findFolders
    'remotes':
        post: remotes.create
    'remotes/:id':
        put: remotes.update
        delete: remotes.destroy
    'remotes/:id/token':
        put: remotes.updateToken