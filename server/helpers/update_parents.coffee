async = require('async')
log = require('printit')
    prefix: 'updateParents'

# To avoid flooding CouchDB when doing a lot of updates in a folder,
# we bulk the parent last modification update and do it asynchronously.
parentFolders = []
timeout = null


# Keep a reference to a parent folder
module.exports.add = (folder) ->
    parentFolders.push folder
    module.exports.resetTimeout()


# After 1 minute of inactivity, update parents
module.exports.resetTimeout = ->
    clearTimeout(timeout) if timeout?
    timeout = setTimeout module.exports.flush, 60 * 1000


# Save in RAM lastModification date for parents
# Update folder parent once all files are uploaded
module.exports.flush = (callback) ->
    async.eachSeries parentFolders, (folder, done) ->
        folder.save done
    , (err) ->
        log.error err if err?
        parentFolders = []
        callback? err
