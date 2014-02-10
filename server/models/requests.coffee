americano = require 'americano-cozy'

module.exports =

    contact:
        all: americano.defaultRequests.all

    config:
        all: americano.defaultRequests.all

    contact_log:
        all: americano.defaultRequests.all
        bySnippet : (doc) ->
            remote = doc.remote.id or doc.remote.tel or doc.remote.mail
            snippet = "#{doc.timestamp} : #{doc.type} "
            snippet += "#{doc.direction} #{remote}"
            emit snippet, doc
        byRemote  : (doc) ->
            remote = doc.remote.id or doc.remote.tel or doc.remote.mail
            emit remote, doc

    phone_communication_log:
        all       : americano.defaultRequests.all
        bySnippet : (doc) -> emit doc.snippet, doc
        byNumber  : (doc) -> emit doc.correspondantNumber, doc

    # Requests required to create tasks
    todolist:
        all: americano.defaultRequests.all

    tree:
        byType: (doc) -> emit doc.type, doc

    task:
        all: americano.defaultRequests.all
