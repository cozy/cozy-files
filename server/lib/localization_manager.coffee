jade = require 'jade'
fs = require 'fs'
cozydb = require 'cozydb'
Polyglot = require 'node-polyglot'

getTemplateExt = require '../helpers/get_template_ext'
ext = getTemplateExt()

class LocalizationManager

    polyglot: null

    # should be run when app starts
    initialize: (callback = () ->) ->
        @retrieveLocale (err, locale) =>
            if err?
                @polyglot = @getPolyglotByLocale null
            else
                @polyglot = @getPolyglotByLocale locale
            callback null, @polyglot

    retrieveLocale: (callback) ->
        cozydb.api.getCozyLocale (err, locale) ->
            if err? or not locale then locale = 'en' # default value
            callback err, locale

    getPolyglotByLocale: (locale) ->
        if locale?
            try
                phrases = require "../locales/#{locale}"
            catch err
                phrases = require '../locales/en'
        else
            phrases = require '../locales/en'
        return new Polyglot locale: locale, phrases: phrases

    # execute polyglot.t, for server-side localization
    t: (key, params = {}) -> return @polyglot?.t key, params

    getEmailTemplate: (name) ->
        filePath = "../views/#{@polyglot.currentLocale}/#{name}"
        templatefile = require('path').join __dirname, filePath
        if ext is 'jade'
            return jade.compile fs.readFileSync templatefile, 'utf8'
        else
            return templatefile

    # for template localization
    getPolyglot: -> return @polyglot

module.exports = new LocalizationManager()
