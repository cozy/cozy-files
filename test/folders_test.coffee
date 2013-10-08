should = require('should')
americano = require('americano')
Client = require('request-json').JsonClient
client = new Client "http://localhost:8888/"
helpers = require './helpers'


describe "Alarms management", ->


    before (done) -> 
        @timeout 5000
        americano.start
            name: 'Files'
            port: 8888
            root: __dirname + '/..'
        , (app, server) =>
            @server = server
            helpers.cleanDb done

    after (done) ->      
        @server.close()
        helpers.cleanDb done

    describe "Create folder", ->
        before helpers.createApp "files", "files", "token", 0, "installed"
        before helpers.cleanDb

        describe "Create a new folder", ->
            it "When I send a request to create a folder", (done) ->
                folder =
                    name: "test"
                    path: "/root"
                    slug: "/root/test"
                client.post "folders/", folder, (err, res, body) =>
                    @err = err
                    @res = res
                    @body = body
                    done()

            it "Then error should not exist", ->
                should.not.exist @err

            it "And 200 should be returned as response code", ->
                @res.statusCode.should.be.equal 200

        describe "Try to create the same folder", ->
            it "When I send a request to create a folder", (done) ->
                folder =
                    name: "test"
                    path: "/root"
                    slug: "/root/test"
                client.post "folders/", folder, (err, res, body) =>
                    @err = err
                    @res = res
                    @body = body
                    done()

            it "Then 400 should be returned as response code", ->
                @res.statusCode.should.be.equal 400  

    describe "Get folder", => 

        it "When I send a request to create a folder", (done) ->
            folder =
                name: "test2"
                path: "/root"
                slug: "/root/test2"
            client.post "folders/", folder, (err, res, body) =>
                @id = body.id
                done()

   	    it "And I send a request to get a folder", (done) ->
            client.get "folders/#{@id}", (err, res, body) =>
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
        	@body.path.should.be.equal "/root"
        	@body.slug.should.be.equal "/root/test2"

    describe "Find folders in a specific folder", => 

        it "When I send a request to create a root folder", (done) ->
            folder =
                name: "root"
                path: "/"
                slug: "/root"
            client.post "folders/", folder, (err, res, body) =>
                @id = body.id
                done()

   	    it "And I send a request to get a folder", (done) ->
            client.get "folders/#{@id}/folders", (err, res, body) =>
                @err = err
                @res = res
                @body = body
                done()

        it "Then error should not exist", ->
            should.not.exist @err

        it "And 200 should be returned as response code", ->
            @res.statusCode.should.be.equal 200

        it "And two folders should be returned", ->
        	@body.length.should.be.equal 2


## Test findFiles ... 

    describe "Delete folder", => 

        it "When I send a request to create a root folder", (done) ->
            folder =
                name: "root2"
                path: "/"
                slug: "/root2"
            client.post "folders/", folder, (err, res, body) =>
                @rootId = body.id
                done()        

        it "And I send a request to create a sub-folder", (done) ->
            folder =
                name: "test3"
                path: "/root2"
                slug: "/root2/test3"
            client.post "folders/", folder, (err, res, body) =>
                @testId = body.id
                done()

   	    it "And I send a request to get a folder", (done) ->
            client.del "folders/#{@rootId}/", (err, res, body) =>
                @err = err
                @res = res
                @body = body
                done()

        it "Then error should not exist", ->
            should.not.exist @err

        it "And 200 should be returned as response code", ->
            @res.statusCode.should.be.equal 200

        it "And root folder should be deleted", (done) ->
            client.get "folders/#{@rootId}/" , (err, res, body) ->
                res.statusCode.should.equal 404
                done()

        it "And sub-folder should be deleted", (done) ->
            client.get "folders/#{@testId}/" , (err, res, body) ->
                res.statusCode.should.equal 404
                done()