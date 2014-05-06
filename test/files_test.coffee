should = require 'should'
americano = require 'americano'
moment = require 'moment'
helpers = require './helpers'

Client = require('request-json').JsonClient
client = new Client "http://localhost:8888/"

describe "Files management", ->

    before helpers.setup 8888

    after helpers.takeDown

    describe "Create file", ->
        #before helpers.cleanDb

        describe "Create a new file", ->
            it "When I send a request to create a file", (done) ->
                file =
                    name: "test"
                    path: ""
                client.sendFile 'files/', './test/test.txt', file, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then error should not exist", ->
                should.not.exist @err

            it "And 200 should be returned as response code", ->
                @res.statusCode.should.be.equal 200

            it "And creationDate and modificationDate should be set", ->
                now = moment()
                body = JSON.parse @body

                should.exist body.creationDate
                should.exist body.lastModification
                body.creationDate.should.be.equal body.lastModification
                creationDate = moment(body.creationDate)
                creationDate.date().should.be.equal now.date()
                creationDate.month().should.be.equal now.month()

        describe "Try to create the same file", ->
            it "When I send a request to create a file", (done) ->
                file =
                    name: "test"
                    path: ""
                path = './test/test.txt'
                client.sendFile 'files/', path, file, (err, res, body) =>
                    @err = err
                    @res = res
                    @body = body
                    done()

            it "Then 400 should be returned as response code", ->
                @res.statusCode.should.be.equal 400


    describe "Get file", =>

        it "When I send a request to create a file", (done) ->
            file =
                name: "test2"
                path: ""
            client.sendFile 'files/', './test/test.txt', file, (err, res, body) =>
                body = JSON.parse(body)
                @body = body
                @id = body.id
                done()

        it "And I send a request to get a file", (done) ->
            client.get "files/#{@id}", (err, res, body) =>
                @err = err
                @res = res
                @body = body
                done()

        it "Then error should not exist", ->
            should.not.exist @err

        it "And 200 should be returned as response code", ->
            @res.statusCode.should.be.equal 200

        it "And folder should be returned", ->
            @body.name.should.be.equal "test2"
            @body.path.should.be.equal ""


    describe "Rename file", =>

        it "When I send a request to create a file", (done) ->
            file =
                name: "test3"
                path: ""
            client.sendFile "files/", './test/test.txt', file, (err, res, body) =>
                body = JSON.parse(body)
                @id = body.id
                done()

        it "And I send a request to rename the file", (done) ->
            file =
                name: "new_test3"
                path: ""
            client.put "files/#{@id}", file, (err, res, body) =>
                @err = err
                @res = res
                done()

        it "Then error should not exist", ->
            should.not.exist @err

        it "And 200 should be returned as response code", ->
            @res.statusCode.should.be.equal 200

        it "And I send a request to get a file", (done) ->
            client.get "files/#{@id}", (err, res, body) =>
                @err = err
                @res = res
                @body = body
                done()

        it "And error should not exist", ->
            should.not.exist @err

        it "And 200 should be returned as response code", ->
            @res.statusCode.should.be.equal 200

        it "And file should be returned", ->
            @body.name.should.be.equal "new_test3"
            @body.path.should.be.equal ""

    describe "Delete file", =>

        it "When I send a request to create a file", (done) ->
            file =
                name: "test4"
                path: ""
            client.sendFile "files/", './test/test.txt', file, (err, res, body) =>
                body = JSON.parse(body)
                @id = body.id
                done()

        it "And I send a request to remove the file", (done) ->
            client.del "files/#{@id}", (err, res, body) =>
                @err = err
                @res = res
                @body = body
                done()

        it "Then error should not exist", ->
            should.not.exist @err

        it "And 200 should be returned as response code", ->
            @res.statusCode.should.be.equal 200

        it "And file should be deleted", (done) ->
            client.get "files/#{@id}" , (err, res, body) ->
                res.statusCode.should.equal 404
                done()

    describe "Tag file", =>
        it "When I send a request to create a file", (done) ->
            file =
                name: "testtags"
                path: ""
            client.sendFile "files/", './test/test.txt', file, (err, res, body) =>
                body = JSON.parse(body)
                @id = body.id
                done()

        it "And I send a request to tag the file", (done) ->
            file =
                name: "testtags"
                path: ""
                tags: ["tag1", "tag2"]
            client.put "files/#{@id}", file, (err, res, body) =>
                @err = err
                @res = res
                done()

        it "Then error should not exist", ->
            should.not.exist @err

        it "And 200 should be returned as response code", ->
            @res.statusCode.should.be.equal 200

        it "And I send a request to get a file", (done) ->
            client.get "files/#{@id}", (err, res, body) =>
                @err = err
                @res = res
                @body = body
                done()

        it "And error should not exist", ->
            should.not.exist @err

        it "And 200 should be returned as response code", ->
            @res.statusCode.should.be.equal 200

        it "And file should have tags", ->
            @body.tags[0].should.be.equal "tag1"
            @body.tags[1].should.be.equal "tag2"
