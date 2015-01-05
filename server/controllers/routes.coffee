index = require './index'
files = require './files'
folders = require './folders'
sharing = require './sharing'
public_auth = require '../middlewares/public_auth'

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

    # Skips the folder retrieval for root actions
    'folders/root/zip/:name':
        get: folders.zip
        post: folders.zip
    'folders/:folderid/zip/:name':
        get: folders.zip
        post: folders.zip

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
    'clearance/contacts/:contactid':
        get: sharing.contact
    'clearance/:shareid':
        get: sharing.details
        put: sharing.change
    'clearance/:shareid/send':
        post: sharing.sendAll

    # public access
    'public/folders':
        post: [public_auth.checkClearance('w', 'folder'), folders.create]
    'public/folders/:folderid/content':
        post: [public_auth.checkClearance('r', 'folder'), folders.findContent]
    'public/folders/:folderid/notifications':
        put: [public_auth.checkClearance('r', 'folder'), folders.changeNotificationsState]
    'public/folders/:folderid/zip/:name':
        get: [public_auth.checkClearance('r', 'folder'), folders.zip]
        post: [public_auth.checkClearance('r', 'folder'), folders.zip]
    'public/folders/:folderid':
        get: folders.publicList

    'public/files':
        post: files.publicCreate # clearanche is checked in the upload process
    'public/files/:fileid/attach/:name':
        get: [public_auth.checkClearance('r', 'file'), files.getAttachment]
    'public/files/:fileid/download/:name':
        get: [public_auth.checkClearance('r', 'file'), files.downloadAttachment]
    'public/files/:fileid':
        get: [public_auth.checkClearance('r', 'file'), files.find]

    'public/search/content':
        post: folders.searchContent
