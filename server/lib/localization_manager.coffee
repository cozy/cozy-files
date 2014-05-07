fs = require 'fs'
Polyglot = require 'node-polyglot'
jade = require 'jade'
Instance = require '../models/cozy_instance'

class LocalizationManager

    polyglot: null

    # should be run when app starts
    initialize: (callback = () ->) ->
        @retrieveLocale (err, locale) =>
            if err? then callback err
            else
                @polyglot = @getPolyglotByLocale locale
                callback null, @polyglot

    retrieveLocale: (callback) ->
        Instance.getLocale (err, locale) ->
            if err? or not locale then locale = 'en' # default value
            callback err, locale

    getPolyglotByLocale: (locale) ->
        try
            phrases = require "../locales/#{locale}"
        catch err
            phrases = require '../locales/en'
        return new Polyglot locale: locale, phrases: phrases

    # execute polyglot.t, for server-side localization
    t: (key, params = {}) -> return @polyglot?.t key, params

    getEmailTemplate: (name) ->
        filePath = "../views/#{@polyglot.currentLocale}/#{name}"
        templatefile = require('path').join __dirname, filePath
        return jade.compile fs.readFileSync templatefile, 'utf8'

    # for template localization
    getPolyglot: -> return @polyglot

module.exports = new LocalizationManager()