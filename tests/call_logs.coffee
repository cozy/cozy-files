fixtures = require './fixtures/data'
fs = require 'fs'
helpers = require './helpers'
expect = require('chai').expect
async  = require 'async'
PhoneCommunicationLog = require '../server/models/phone_communication_log'

describe 'Call Logs', ->

    before helpers.startServer
    before helpers.clearDb
    before helpers.createContact fixtures.contact1

    before helpers.makeTestClient
    after  helpers.killServer

    describe 'Create logs (first merge) - POST /calls', ->

        it 'should allow requests', (done) ->
            @client.post "calls", fixtures.logs1, done

        it 'should reply with 201 status', ->
            expect(@response.statusCode).to.eql 201


    describe 'Get logs - GET /contact/:id/calls', ->

        it 'should allow requests', (done) ->
            @timeout 5000
            @client.get "contacts/#{@contact.id}/calls", done

        it 'should reply with the logs for this contact numbers (2)', ->
            expect(@body).to.be.an 'array'
            expect(@body).to.have.length 2

    describe 'Merge logs - POST /calls (same logs + some new)', ->

        it 'should allow requests', (done) ->
            @client.post "calls", fixtures.logs2, done

        it 'then, when i get', (done) ->
            @timeout 5000
            @client.get "contacts/#{@contact.id}/calls", done

        it 'should reply with the logs (now 3)', ->
            expect(@body).to.be.an 'array'
            expect(@body).to.have.length 3

    describe 'Same logs arrive by another channel', ->

        it 'raw logs creation', (done) ->

            createLog = (data, callback) ->
                data.origin = 'Orange'
                PhoneCommunicationLog.create data, callback

            async.eachSeries fixtures.logsOrange, createLog, done

        it 'wait for dedup to happen', (done) ->
            @timeout 5000
            console.log " "
            setTimeout done, 4000

    describe 'dedup succeded', (done) ->

        it 'when i get logs', (done) ->
            @timeout 5000
            @client.get "contacts/#{@contact.id}/calls", done

        it 'should reply with the logs (now 3)', ->
            expect(@body).to.be.an 'array'
            expect(@body).to.have.length 3