async = require 'async'
Client = require('request-json').JsonClient

CozyInstance = require '../models/cozy_instance'

module.exports.main = (req, res, next) ->
    async.parallel [
        (cb) -> CozyInstance.getLocale cb
    ], (err, results) =>

        if err then next err
        else
            [locale] = results
            res.render 'index.jade', imports: """
                window.locale = "#{locale}";
            """

module.exports.tags = (req, res, next) ->
    dataSystem = new Client "http://localhost:9101/"
    dataSystem.get 'tags', (err, response, body) ->
        if err? then next err
        else
            res.send 200, body