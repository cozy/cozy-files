fixtures = require './fixtures/data'
fs = require 'fs'
helpers = require './helpers'
expect = require('chai').expect

describe 'Read operations', ->

    before helpers.clearDb
    before helpers.createContact fixtures.contact1

    before helpers.startServer
    before helpers.makeTestClient
    after  helpers.killServer

    describe 'List - GET /contacts', ->

        it 'should allow requests', (done) ->
            @client.get 'contacts', done

        it 'should reply with the list of contacts', ->
            expect(@body).to.be.an 'array'
            expect(@body).to.have.length 1
            expect(@body[0].id).to.exist
            expect(@body[0].name).to.equal fixtures.contact1.name
            @id = @body[0].id

    describe 'Read - GET /contacts/:id', ->

        it 'should allow requests', (done) ->
            @client.get "contacts/#{@id}", done

        it 'should reply with one contact', ->
            expect(@body.name).to.equal fixtures.contact1.name
            expect(@body.notes).to.equal fixtures.contact1.notes
            expect(@body.id).to.exist

    describe 'Create - POST /albums', ->

        contact =
            name: 'Jane Smith'

        it 'should allow requests', (done) ->
            @client.post 'contacts', contact, done

        it 'should reply with the created contact', ->
            expect(@body.name).to.equal contact.name
            expect(@body.id).to.exist
            @id = @body.id

    describe 'Update - PUT /albums/:id', ->

        update =
            notes: 'funny guy'

        it 'should allow requests', (done) ->
            @client.put "contacts/#{@id}", update, done

        it 'should reply with the updated album', ->
            expect(@body.notes).to.equal update.notes

        it 'when I GET the album', (done) ->
            @client.get "contacts/#{@id}", done

        it 'then it is changed', ->
            expect(@body.notes).to.equal update.notes

    describe 'Delete - DELETE /cotacts/:id', ->

        update =
            notes: 'funny guy'

        it 'should allow requests', (done) ->
            @client.del "contacts/#{@id}", done

        it 'should reply with 204 status', ->
            expect(@response.statusCode).to.equal 204

        it 'when I GET the album', (done) ->
            @client.get "contacts/#{@id}", done

        it 'then i get an error', ->
            expect(@response.statusCode).to.equal 404