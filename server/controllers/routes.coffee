files = require './files'
folders = require './folders'

module.exports =

    'fileid':
        param: files.fetch

    'files':
        get: files.all
        post: files.create
    'files/:fileid':
        get: files.find
        put: files.modify
        delete: files.destroy
    'files/:fileid/attach/:name':
        get: files.getAttachment
    'files/:fileid/download/:name':
        get: files.downloadAttachment

    # public access to the file
    'public/files/:fileid':
        get: files.publicDownloadAttachment
    'fileshare/:fileid':
        get: files.getPublicLink
    'fileshare/:fileid/send':
        post: files.sendPublicLinks

    # public access to the folder
    'public/folders/:id':
        get: folders.zip
    'foldershare/:id':
        get: folders.getPublicLink
    'foldershare/:id/send':
        post: folders.sendPublicLinks

    'folders':
        post: folders.create
    'folder/tree/:id':
        get: folders.tree
    'folders/:id':
        get: folders.find
        put: folders.modify
        delete: folders.destroy
    'folders/:id/zip/:name':
        get: folders.zip

    'folders/files':
        post: folders.findFiles
    'folders/folders':
        post: folders.findFolders

    'search/folders':
        post: folders.search
    'search/files':
        post: files.search
