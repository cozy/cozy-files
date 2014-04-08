should = require('should')
Client = require('request-json').JsonClient
client = new Client "http://localhost:8888/"
helpers = require './helpers'


describe "Sharing management", ->

    before helpers.setup 8888
    after helpers.takeDown

    describe "No regression on #25", ->
        it "When I get contacts list", (done) ->
            client.get "contacts",  (err, res, body) =>
                should.not.exist err
                res.statusCode.should.equal 200
                done()
