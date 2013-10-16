americano = require 'americano-cozy'

module.exports =

    contact:
        all: americano.defaultRequests.all

    phone_communication_log:
        all       : americano.defaultRequests.all
        bySnippet : (doc) -> emit doc.snippet, doc
        byNumber  : (doc) -> emit doc.correspondantNumber, doc
