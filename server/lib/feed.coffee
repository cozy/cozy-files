module.exports = class Feed

    axonSock: undefined

    constructor: ->
        @logger = require('printit')
            date: true
            prefix: 'helper/db_feed'

    initialize: (server) ->
        @startPublishingToAxon()

        server.on 'close', =>
            @axonSock.close()  if @axonSock?

    startPublishingToAxon: ->
        axon = require 'axon'
        @axonSock = axon.socket 'pub'
        axonPort =  parseInt process.env.AXON_PORT or 9105
        @axonSock.connect axonPort
        @logger.info 'Pub server started'

    publish: (event, id) =>
        @logger.info "Publishing #{event} #{id}"
        @axonSock.send event, id if @axonSock?
        
module.exports = new Feed()
