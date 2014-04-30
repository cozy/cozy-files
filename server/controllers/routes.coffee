files = require './files'
folders = require './folders'
sharing = require './sharing'

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

    # clearance
    'shareid':
        param: sharing.fetch
    'clearance/contacts':
        get: sharing.contactList
    'clearance/contacts/:contactid.jpg':
        get: sharing.contactPicture
    'clearance/:shareid':
        get: sharing.details
        put: sharing.change
    'clearance/:shareid/send':
        post: sharing.sendAll

    # public access
    'public/folders':
        post: folders.publicCreate
    'public/files':
        post: files.publicCreate
    'public/files/:fileid':
        get: files.publicDownloadAttachment
    'public/folders/:id.zip':
        get: folders.publicZip
    'public/folders/:id':
        get: folders.publicList
