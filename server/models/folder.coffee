cozydb = require 'cozydb'
moment = require 'moment'
async = require 'async'

module.exports = Folder = cozydb.getModel 'Folder',
    path: String
    name: String
    docType: String
    creationDate: String
    lastModification: String
    size: Number
    modificationHistory: Object
    changeNotification: Boolean
    clearance: cozydb.NoSchema
    tags: [String]

Folder.all = (params, callback) ->
    Folder.request "all", params, callback

Folder.byFolder = (params, callback) ->
    Folder.request "byFolder", params, callback

Folder.byFullPath = (params, callback) ->
    Folder.request "byFullPath", params, callback


Folder.injectInheritedClearance = (folders, callback) ->
    async.map folders, (folder, cb) ->
        regularFolder = folder.toObject()
        folder.getInheritedClearance (err, inheritedClearance) ->
            regularFolder.inheritedClearance = inheritedClearance
            cb err, regularFolder
    , callback


# New folder Creation process:
# * Create new folder.
# * Index the folder name.
Folder.createNewFolder = (folder, callback) ->
    Folder.create folder, (err, newFolder) ->
        if err then callback err
        else
            newFolder.index ["name"], (err) ->
                console.log err if err
                callback null, newFolder

Folder.allPath = (callback) ->
    Folder.request "byFullPath", (err, folders) ->
        return callback err if err
        paths = []
        paths.push folder.getFullPath() for folder in folders
        callback null, paths

Folder::getFullPath = ->
    "#{@path}/#{@name}"

Folder::getParents = (callback) ->
    foldersOfPath = @getFullPath().split '/'
    parentFoldersPath = []

    # extract all parent's full path
    while foldersOfPath.length > 0
        parent = foldersOfPath.join '/'

        # Root and current folder aren't in the parents
        parentFoldersPath.push parent if parent not in ['', @getFullPath()]
        foldersOfPath.pop()

    Folder.byFullPath keys: parentFoldersPath.reverse(), callback

Folder::getPublicURL = (cb) ->
    cozydb.api.getCozyDomain (err, domain) =>
        return cb err if err
        url = "#{domain}public/files/folders/#{@id}"
        cb null, url

Folder::getInheritedClearance = (callback) ->

    @getParents (err, parents) ->
        return callback err if err?

        # if we check a folder, we must exclude the folder itself from
        #the parent's tree otherwise we can't change its clearance afterwards
        parents.shift() if parents.length > 0 and parents[0].id is @id

        # keep only element of path that alter the clearance
        isPublic = false
        inherited = parents?.filter (parent) ->
            parent.clearance = [] unless parent.clearance?

            if isPublic then return false

            isPublic = true if parent.clearance is 'public'
            return parent.clearance.length isnt 0

        callback null, inherited

Folder::updateParentModifDate = (callback) ->
    Folder.byFullPath key: @path, (err, parents) ->
        if err
            callback err
        else if parents.length > 0
            parent = parents[0]
            parent.lastModification = moment().toISOString()
            parent.save callback
        else
            callback()


if process.env.NODE_ENV is 'test'
    Folder::index = (fields, callback) -> callback null
    Folder::search = (query, callback) -> callback null, []

