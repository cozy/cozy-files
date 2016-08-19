async = require('async')
log = require('printit')
    prefix: 'updateParents'

# To avoid flooding CouchDB when doing a lot of updates in a folder,
# we bulk the parent last modification update and do it asynchronously.
parentFolders = {}
timeout = null


# Keep a reference to a parent folder
module.exports.add = (folder, lastModification) ->
    folder.lastModification = lastModification
    fullpath = "#{folder.path}/#{folder.name}"
    parentFolders[fullpath] =
        folder: folder
        lastModification: lastModification
    module.exports.resetTimeout()


# After 1 minute of inactivity, update parents
module.exports.resetTimeout = ->
    clearTimeout(timeout) if timeout?
    timeout = setTimeout module.exports.flush, 60 * 1000


# Save in RAM lastModification date for parents
# Update folder parent once all files are uploaded
module.exports.flush = (callback) ->
    async.forEachOfSeries parentFolders, (entry, fullpath, done) ->
        data = lastModification: entry.lastModification
        entry.folder.updateAttributes data, done
    , (err) ->
        log.error err if err?
        parentFolders = {}
        callback? err
