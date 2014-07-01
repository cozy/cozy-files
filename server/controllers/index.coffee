async = require 'async'
Client = require('request-json').JsonClient

CozyInstance = require '../models/cozy_instance'

module.exports.main = (req, res, next) ->
    async.parallel [
        (cb) -> CozyInstance.getLocale cb
        (cb) ->
            dataSystem = new Client "http://localhost:9101/"
            dataSystem.get 'tags', (err, response, body) ->
                err = err or body.error
                cb err, body
    ], (err, results) =>

        if err then next err
        else
            [locale, tags] = results
            res.render 'index.jade', imports: """
                window.locale = "#{locale}";
                window.tags = "#{tags}".split(',');
            """