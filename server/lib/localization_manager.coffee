jade = require 'jade'
fs = require 'fs'
cozydb = require 'cozydb'
Polyglot = require 'node-polyglot'

getTemplateExt = require '../helpers/get_template_ext'
ext = getTemplateExt()

class LocalizationManager

    polyglot: null

    # should be run when app starts
    initialize: (callback = ->) ->
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
        # get path of template in a language
        getPath = (lang) ->
            filePath = "../views/#{lang}/#{name}"
            templatefile = require('path').join __dirname, filePath
            if ext isnt 'jade'
                templatefile = templatefile.replace('jade', 'js')
            if fs.existsSync(templatefile)
                return templatefile
            else
                null

        # If template doesn't exists, use english as default
        templatePath = getPath @polyglot.currentLocale
        if not templatePath?
            templatePath = getPath 'en'

        if ext is 'jade'
            return jade.compile fs.readFileSync templatePath, 'utf8'
        else
            return require(templatePath)

    # for template localization
    getPolyglot: -> return @polyglot

module.exports = new LocalizationManager()
