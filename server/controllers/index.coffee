async = require 'async'
cozydb = require 'cozydb'

module.exports.main = (req, res, next) ->
    async.parallel [
        (cb) -> cozydb.api.getCozyLocale cb
        (cb) -> cozydb.api.getCozyTags cb
        (cb) -> cozydb.api.getCozyInstance cb
    ], (err, results) =>

        if err then next err
        else
            [locale, tags, instance] = results
            if instance?.domain? and instance.domain isnt 'domain.not.set'
                domain = "https://#{instance.domain}/public/files/"
            else
                domain = false
            res.render "index", imports: """
                window.locale = "#{locale}";
                window.tags = "#{tags.join(',').replace('\"', '')}".split(',');
                window.domain = "#{domain}";
            """
