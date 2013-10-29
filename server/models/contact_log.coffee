americano = require 'americano-cozy'
async = require 'async'

# this is a cozy-contact log

module.exports = ContactLog = americano.getModel 'ContactLog',
    type                : String
    direction           : type: String, default: 'NA'
    timestamp           : String
    remote              : Object
    content             : (x) -> x
    wrong               : type: Boolean, default: false

ContactLog.byRemote = (keys, callback) ->
    ContactLog.request 'byRemote', keys: keys, callback

ContactLog.bySnippet = (keys, callback) ->
    ContactLog.rawRequest 'bySnippet', keys: keys, (err, items) ->
        return callback err if err
        indexed = {}
        indexed[item.key] = item.value for item in items
        callback null, indexed

ContactLog.normalizeNumber = (number) ->
    number = number.replace ' ', ''
    number = number.replace '-', ''
    number = number.replace '+', ''
    return number

ContactLog.makeSnippet = (log) ->
    if log.snippet then return log.snippet
    else
        remote = log.remote?.id or log.remote?.tel or log.remote?.mail
        return "#{log.timestamp} : #{log.type} #{log.direction} #{remote}"

ContactLog.merge = (newLogs, callback) ->
    snippets = newLogs.map ContactLog.makeSnippet

    # fetch all old logs wich could conflict
    ContactLog.bySnippet snippets, (err, oldlogs) ->
        return callback err if err

        async.eachSeries newLogs, (log, cb) ->
            # ignore existing logs
            snippet = ContactLog.makeSnippet(log)
            if oldlogs[snippet]?
                return cb null
            else
                ContactLog.create log, cb
        , callback