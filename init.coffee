Contact = require './server/models/contact'

# MapReduce's map for "all" request
allMap = (doc) -> emit doc._id, doc

# Create all requests and upload directory
module.exports = init = (done) ->
    Contact.defineRequest 'all', allMap, (err) ->
        if err
            console.log "Something went wrong"
            console.log err.stack
        else
            console.log "Requests have been created"

        done(err) if done

# so we can do "coffee init"
init() if not module.parent