americano = require 'americano-cozy'

module.exports =

    contact:
        all       : americano.defaultRequests.all

    contact_log:
        all       : americano.defaultRequests.all
        bySnippet : (doc) ->
            remote = doc.remote.id or doc.remote.tel or doc.remote.mail
            snippet = "#{doc.timestamp} : #{doc.type} "
            snippet += "#{doc.direction} #{remote}"
            emit snippet, doc
        byRemote  : (doc) ->
            remote = doc.remote.id or doc.remote.tel or doc.remote.mail
            emit remote, doc

    # mail:
    #     byMail : (doc) ->
    #         emit from, doc
    #         emit to.split(','), doc
    #         emit cc.split(','), doc
    #         emit bcc.split(','), doc

    # mail_sent:
    #     byMail : (doc) ->
    #         emit from, doc
    #         emit to.split(','), doc
    #         emit cc.split(','), doc
    #         emit bcc.split(','), doc

    phone_communication_log:
        all       : americano.defaultRequests.all
        bySnippet : (doc) -> emit doc.snippet, doc
        byNumber  : (doc) -> emit doc.correspondantNumber, doc
