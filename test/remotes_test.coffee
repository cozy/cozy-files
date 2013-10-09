should = require('should')
americano = require('americano')
Client = require('request-json').JsonClient
client = new Client "http://localhost:8888/"
helpers = require './helpers'


describe "Remotes management", ->


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

    describe "Create remotes", ->
        describe "Create remotes without specific name", ->
        	it "When I send a request to create a remote", (done) ->
                client.post "remotes/", {}, (err, res, body) =>
                    @err = err
                    @res = res
                    @body = body
                    done()

            it "Then error should not exist", ->
                should.not.exist @err

            it "And 200 should be returned as response code", ->
                @res.statusCode.should.be.equal 200

            it "And remote should be have a login and a password", ->
                @body.password.should.be.exist
                @body.login.should.be.exist

        describe "Create remotes with specific name", ->
        	it "When I send a request to create a remote", (done) ->
                client.post "remotes/", {login: "test"}, (err, res, body) =>
                    @err = err
                    @res = res
                    @body = body
                    done()

            it "Then error should not exist", ->
                should.not.exist @err

            it "And 200 should be returned as response code", ->
                @res.statusCode.should.be.equal 200

            it "And remote should be have a login and a password", ->
                @body.password.should.be.exist
                @body.login.should.be.equal 'test'    


    describe "Update remotes", ->
        describe "Update field other than password", ->
            it "When I send a request to create a remote", (done) ->
                client.post "remotes/", {login: "test"}, (err, res, body) =>
                    @id = body.id
                    done()

            it "And I send a request to create a remote", (done) ->
                client.put "remotes/#{@id}", {login: "newTest"}, (err, res, body) =>
                    @err = err
                    @res = res
                    @body = body
                    done()

            it "Then error should not exist", ->
                should.not.exist @err

            it "And 200 should be returned as response code", ->
                @res.statusCode.should.be.equal 200

            it "And remote should be have a login and a password", ->
                @body.password.should.be.exist
                @body.login.should.be.equal 'newTest'    

        describe "Try to update password", ->
            it "When I send a request to create a remote", (done) ->
                client.post "remotes/", {login: "test"}, (err, res, body) =>
                    @id = body.id
                    done()

            it "And I send a request to create a remote", (done) ->
                client.put "remotes/#{@id}", {login: "newTest", password: "newPassword"}, (err, res, body) =>
                    @err = err
                    @res = res
                    @body = body
                    done()

            it "Then error should not exist", ->
                should.not.exist @err

            it "And 200 should be returned as response code", ->
                @res.statusCode.should.be.equal 200

            it "And remote should be have a login and a password", ->
                @body.password.should.be.exist
                @body.password.should.not.be.equal "newPassword"
                @body.login.should.be.equal 'newTest'   

        describe "Update password", ->
            it "When I send a request to create a remote", (done) ->
                client.post "remotes/", {login: "test"}, (err, res, body) =>
                    @id = body.id
                    @password = body.password
                    done()

            it "And I send a request to create a remote", (done) ->
                client.put "remotes/#{@id}/token", {}, (err, res, body) =>
                    @err = err
                    @res = res
                    @body = body
                    done()

            it "Then error should not exist", ->
                should.not.exist @err

            it "And 200 should be returned as response code", ->
                @res.statusCode.should.be.equal 200

            it "And remote should be have a login and a password", ->
                @body.password.should.be.exist
                @body.password.should.not.be.equal @password
                @body.login.should.be.equal 'test'     


    describe "Delete remotes", ->
        it "When I send a request to create a remote", (done) ->
            client.post "remotes/", {login: "test"}, (err, res, body) =>
                @id = body.id
                done()

        it "And I send a request to delete this remote", (done) ->
            client.del "remotes/#{@id}", (err, res, body) =>
                @err = err
                @res = res
                @body = body
                done()

        it "And 200 should be returned as response code", ->
            @res.statusCode.should.be.equal 200

        it "And remote should be deleted", (done) -> 
            client.put "remotes/#{@id}/token", {}, (err, res, body) =>
                res.statusCode.should.be.equal 404
                done()