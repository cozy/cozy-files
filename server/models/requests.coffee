cozydb = require 'cozydb'

module.exports =
    file:
        all: cozydb.defaultRequests.all
        byTag: cozydb.defaultRequests.tags
        byFolder: cozydb.defaultRequests.by 'path'
        byFullPath: (doc) -> emit (doc.path + '/' + doc.name), doc
    folder:
        all: cozydb.defaultRequests.all
        byTag: cozydb.defaultRequests.tags
        byFolder: cozydb.defaultRequests.by 'path'
        byFullPath: (doc) -> emit (doc.path + '/' + doc.name), doc

    contact:
        all: cozydb.defaultRequests.all

    user:
        all: cozydb.defaultRequests.all
