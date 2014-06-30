index = require './index'
files = require './files'
folders = require './folders'
sharing = require './sharing'

module.exports =

    '': get: index.main

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


    'folderid':
        param: folders.fetch

    'folders':
        post: folders.create
    'folder/tree/:folderid':
        get: folders.tree
    'folders/content': post: folders.findContent
    'folders/list':
        get: folders.list
    'folders/files':
        post: folders.findFiles
    'folders/folders':
        get: folders.allFolders
        post: folders.findFolders
    'folders/:folderid':
        get: folders.find
        put: folders.modify
        delete: folders.destroy
    'folders/:folderid/zip/:name':
        get: folders.zip

    'search/folders':
        post: folders.search
    'search/files':
        post: files.search
    'search/content':
        post: folders.searchContent

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
    'public/folders/:folderid.zip':
        get: folders.publicZip
    'public/folders/:folderid':
        get: folders.publicList
