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
                expect(config.nameOrder).to.eql 'not-set'

    describe 'Change config (first) - POST /config', ->

        it 'should allow requests', (done) ->
            @client.post 'config', nameOrder: 'given-initial-familly', done

        it 'should reply with updated config', ->
            expect(@err).to.not.exist
            expect(@body).to.have.property 'nameOrder', 'given-initial-familly'

        it 'and the update has been stored in db', (done) ->
            Config.getInstance (err, config) ->
                expect(@err).to.not.exist
                expect(config.nameOrder).to.eql 'given-initial-familly'
                done()

    describe 'Change config (again) - POST /config', ->

        it 'should allow requests', (done) ->
            @client.post 'config', nameOrder: 'familly-given', done

        it 'should reply with updated config', ->
            expect(@err).to.not.exist
            expect(@body).to.have.property 'nameOrder', 'familly-given'

        it 'and the update has been stored in db', (done) ->
            Config.getInstance (err, config) ->
                expect(@err).to.not.exist
                expect(config.nameOrder).to.eql 'familly-given'
                done()
