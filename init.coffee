Contact = require './server/models/contact'
patch1 = require './server/patches/patch1'

# MapReduce's map for "all" request
allMap = (doc) -> emit doc._id, doc

# Create all requests and upload directory
module.exports = init = (callback) ->
    Contact.defineRequest 'all', allMap, (err) ->
        if err
            callback err
        else
            patch1 callback


# so we can do "coffee init"
if not module.parent
    init (err) ->
        if err
            console.log "init failled"
            console.log err.stack
        else
            console.log "init success"