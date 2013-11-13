helpers = require './helpers'
Config = require '../server/models/config'
expect = require('chai').expect

describe 'Config', ->

    before helpers.startServer
    before helpers.clearDb

    before helpers.makeTestClient
    after  helpers.killServer

    describe 'Default config', ->

        it 'If no config exists, getInstance return the default config', ->
            Config.getInstance (err, config) ->
                expect(@err).to.not.exist
                expect(config.nameOrder).to.eql 'firstname'

    describe 'Change config - POST /config', ->

        it 'should allow requests', (done) ->
            # getLocale is very long, this need to be fixed
            @timeout 5000
            @client.post 'config', nameOrder: 'lastname', done

        it 'should reply with updated config', ->
            expect(@err).to.not.exist
            expect(@body).to.have.property 'nameOrder', 'lastname'

        it 'and the update has been stored in db', (done) ->
            Config.getInstance (err, config) ->
                expect(@err).to.not.exist
                expect(config.nameOrder).to.eql 'lastname'
                done()