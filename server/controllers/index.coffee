async = require 'async'

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