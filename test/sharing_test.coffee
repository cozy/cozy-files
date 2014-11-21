should = require('chai').should()

helpers = require './helpers'
client = helpers.getClient()

htmlGet = (url, cb) ->
    req = client.get url, cb, false
    req.headers['accept'] = 'text/html'

describe "Sharing management", ->

    before helpers.startApp
    before helpers.cleanDB
    before helpers.ensureCozyInstance
    after helpers.stopApp
    after helpers.cleanDB

    describe "No regression on #25", ->
        it "When I get contacts list", (done) ->
            client.get "clearance/contacts",  (err, res, body) =>
                should.not.exist err
                res.statusCode.should.equal 200
                done()

    describe 'public', ->

        it "When I create a public folder", (done) ->
            folder =
                name: "public_folder"
                path: "/root"
                clearance: 'public'
            client.post "folders/", folder, (err, res, body) =>
                @id = body.id
                done()

        it "And I send a request to get the folder publicly", (done) ->
            htmlGet "public/folders/#{@id}", (err, res, body) =>
                should.not.exist err
                res.statusCode.should.equal 200
                done()

    describe 'readonly sharing', ->

        it "When I create a read-only shared folder", (done) ->
            folder =
                name: "readonly"
                path: "/root"
                clearance: [ {
                    "email":"john@example.com",
                    "contactid":"9D3EEDCA-F96D-8BA7-B2AA-AC665ADF43C1",
                    "key":"secret",
                    "perm":"r"
                    } ]

            client.post "folders/", folder, (err, res, body) =>
                @id = body.id
                done()

        it "I cant get the folder with no key", (done) ->
            htmlGet "public/folders/#{@id}", (err, res, body) =>
                should.not.exist err
                res.statusCode.should.equal 404
                done()

        it "I can get the folder with a key", (done) ->
            htmlGet "public/folders/#{@id}?key=secret", (err, res, body) =>
                should.not.exist err
                res.statusCode.should.equal 200
                done()

        it "I cant upload a file with the key", (done) ->
            file =
                name: "test"
                path: "/readonly"
            client.sendFile 'public/files/?key=secret', './test/fixtures/files/test.txt', file, (err, res, body) =>
                should.not.exist err
                res.statusCode.should.equal 401
                done()

    describe 'writable sharing', ->

        it "When I create a write-allowed shared folder", (done) ->
            folder =
                name: "writable"
                path: "/root"
                clearance: [ {
                    "email":"john@example.com",
                    "contactid":"9D3EEDCA-F96D-8BA7-B2AA-AC665ADF43C1",
                    "key":"secret2",
                    "perm":"rw"
                    } ]

            client.post "folders/", folder, (err, res, body) =>
                @id = body.id
                done()

        it "I cant get the folder with no key", (done) ->
            htmlGet "public/folders/#{@id}", (err, res, body) =>
                should.not.exist err
                res.statusCode.should.equal 404
                done()

        it "I can get the folder with a key", (done) ->
            htmlGet "public/folders/#{@id}?key=secret2", (err, res, body) =>
                should.not.exist err
                res.statusCode.should.equal 200
                done()

        it "I can upload a file with the key", (done) ->
            file =
                name: "test"
                path: "/root/writable"
            client.sendFile 'public/files/?key=secret2', './test/fixtures/files/test.txt', file, (err, res, body) =>
                should.not.exist err
                res.statusCode.should.equal 200
                done()
