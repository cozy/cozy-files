fixtures = require './fixtures/data'
fs = require 'fs'
helpers = require './helpers'
expect = require('chai').expect

describe 'Contacts', ->

    before helpers.init
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
            expect(@body[0].fn).to.equal fixtures.contact1.fn
            @id = @body[0].id

    describe 'Read - GET /contacts/:id', ->

        it 'should allow requests', (done) ->
            @client.get "contacts/#{@id}", done

        it 'should reply with one contact', ->
            expect(@body.fn).to.equal fixtures.contact1.fn
            expect(@body.note).to.equal fixtures.contact1.note
            expect(@body.id).to.exist

    describe 'Create - POST /contacts', ->

        contact =
            name: 'Jane Smith'

        it 'should allow requests', (done) ->
            @client.post 'contacts', contact, done

        it 'should reply with the created contact', ->
            expect(@body.fn).to.equal contact.fn
            expect(@body.id).to.exist
            @id = @body.id

    describe 'Update - PUT /contacts/:id', ->

        update =
            note: 'funny guy'

        it 'should allow requests', (done) ->
            @client.put "contacts/#{@id}", update, done

        it 'should reply with the updated album', ->
            expect(@body.note).to.equal update.note

        it 'when I GET the album', (done) ->
            @client.get "contacts/#{@id}", done

        it 'then it is changed', ->
            expect(@body.note).to.equal update.note

    describe 'Delete - DELETE /contacts/:id', ->

        it 'should allow requests', (done) ->
            @client.del "contacts/#{@id}", done

        it 'should reply with 204 status', ->
            expect(@response.statusCode).to.equal 204

        it 'when I GET the album', (done) ->
            @client.get "contacts/#{@id}", done

        it 'then i get an error', ->
            expect(@response.statusCode).to.equal 404