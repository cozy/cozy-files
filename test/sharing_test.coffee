should = require('chai').should()

helpers = require './helpers'
client = helpers.getClient()

describe "Sharing management", ->

    before helpers.cleanDB
    before helpers.startApp
    after helpers.stopApp
    after helpers.cleanDB

    describe "No regression on #25", ->
        it "When I get contacts list", (done) ->
            client.get "clearance/contacts",  (err, res, body) =>
                should.not.exist err
                res.statusCode.should.equal 200
                done()
