should = require('should')
americano = require('americano')
Client = require('request-json').JsonClient
client = new Client "http://localhost:8888/"
helpers = require './helpers'

describe "Files management", ->

    before (done) -> 
        @timeout 6000
        helpers.createApp "files", "files", "token", 0, "installed"
        port = process.env.PORT || 8888
        setTimeout () =>
            americano.start name: 'files', port: port, (app, server) =>
                @server = server
                done()
        , 3000

    after (done) ->      
        @server.close()
        helpers.cleanDb done

    describe "Create file", ->
        #before helpers.cleanDb

        describe "Create a new file", ->
            it "When I send a request to create a file", (done) ->
                file =
                    name: "test"
                    path: ""
                client.sendFile 'files/', './test/test.txt', file, (err, res, body) =>
                    done()

            it "Then error should not exist", ->
                should.not.exist @err

            it "And 200 should be returned as response code", ->
                @res.statusCode.should.be.equal 200

        describe "Try to create the same file", ->
            it "When I send a request to create a folder", (done) ->
                file =
                    name: "test"
                    path: ""
                client.sendFile 'files/', './test/test.txt', file, (err, res, body) =>
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
