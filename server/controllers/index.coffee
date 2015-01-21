async = require 'async'
cozydb = require 'cozydb'

module.exports.main = (req, res, next) ->
    async.parallel [
        (cb) -> cozydb.api.getCozyLocale cb
        (cb) -> cozydb.api.getCozyTags cb
    ], (err, results) =>

        if err then next err
        else
            [locale, tags] = results
            res.render 'index.jade', imports: """
                window.locale = "#{locale}";
                window.tags = "#{tags.join(',').replace('\"', '')}".split(',');
            """
