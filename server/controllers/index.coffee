async = require 'async'
cozydb = require 'cozydb'

module.exports.main = (req, res, next) ->
    async.parallel [
        (cb) -> cozydb.api.getCozyLocale cb
        (cb) -> cozydb.api.getCozyTags cb
        (cb) -> cozydb.api.getCozyInstance cb
    ], (err, results) ->

        if err then next err
        else
            [locale, tags, instance] = results
            if instance?.domain? and instance.domain isnt 'domain.not.set'
                # Parse domain
                domain = instance.domain
                if domain.indexOf('https') is -1
                    domain = "https://#{domain}"
                if domain.slice('-1') is "/"
                    domain = domain.substring 0, domain.length-1
                domain = domain + "/public/files/"
            else
                domain = false
            res.render "index", imports: """
                window.locale = "#{locale}";
                window.tags = "#{tags.join(',').replace('\"', '')}".split(',');
                window.domain = "#{domain}";
            """
