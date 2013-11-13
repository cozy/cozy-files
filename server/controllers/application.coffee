Contact = require '../models/contact'
Config  = require '../models/config'
i18n    = require 'cozy-i18n-helper'
async   = require 'async'


getImports = (callback) ->
    async.parallel [
        (cb) -> Contact.request 'all', cb
        (cb) -> Config.getInstance cb
        (cb) -> i18n.getLocale null, cb
    ], (err, results) ->
        [contacts, config, locale] = results
        callback null, """
            window.config = #{JSON.stringify(config)};
            window.locale = "#{locale}";
            window.initcontacts = #{JSON.stringify(contacts)};
        """


module.exports =

    index: (req, res) ->
        getImports (err, imports) ->
            return res.error 500, 'An error occured', err if err

            res.render 'index.jade', imports: imports


    widget: (req, res) ->
        getImports (err, imports) ->
            return res.error 500, 'An error occured', err if err

            res.render 'widget.jade', imports: imports


    setConfig: (req, res) ->
        Config.set req.body, (err, config) ->
            return res.error 500, 'An error occured', err if err
            res.send config