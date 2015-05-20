// Generated by CoffeeScript 1.9.0
var LocalizationManager, Polyglot, cozydb, ext, fs, getTemplateExt, jade;

jade = require('jade');

fs = require('fs');

cozydb = require('cozydb');

Polyglot = require('node-polyglot');

getTemplateExt = require('../helpers/get_template_ext');

ext = getTemplateExt();

LocalizationManager = (function() {
  function LocalizationManager() {}

  LocalizationManager.prototype.polyglot = null;

  LocalizationManager.prototype.initialize = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    return this.retrieveLocale((function(_this) {
      return function(err, locale) {
        if (err != null) {
          _this.polyglot = _this.getPolyglotByLocale(null);
        } else {
          _this.polyglot = _this.getPolyglotByLocale(locale);
        }
        return callback(null, _this.polyglot);
      };
    })(this));
  };

  LocalizationManager.prototype.retrieveLocale = function(callback) {
    return cozydb.api.getCozyLocale(function(err, locale) {
      if ((err != null) || !locale) {
        locale = 'en';
      }
      return callback(err, locale);
    });
  };

  LocalizationManager.prototype.getPolyglotByLocale = function(locale) {
    var err, phrases;
    if (locale != null) {
      try {
        phrases = require("../locales/" + locale);
      } catch (_error) {
        err = _error;
        phrases = require('../locales/en');
      }
    } else {
      phrases = require('../locales/en');
    }
    return new Polyglot({
      locale: locale,
      phrases: phrases
    });
  };

  LocalizationManager.prototype.t = function(key, params) {
    var _ref;
    if (params == null) {
      params = {};
    }
    return (_ref = this.polyglot) != null ? _ref.t(key, params) : void 0;
  };

  LocalizationManager.prototype.getEmailTemplate = function(name) {
    var filePath, templatefile;
    filePath = "../views/" + this.polyglot.currentLocale + "/" + name;
    templatefile = require('path').join(__dirname, filePath);
    if (ext === 'jade') {
      return jade.compile(fs.readFileSync(templatefile, 'utf8'));
    } else {
      templatefile = templatefile.replace('jade', 'js');
      return require(templatefile);
    }
  };

  LocalizationManager.prototype.getPolyglot = function() {
    return this.polyglot;
  };

  return LocalizationManager;

})();

module.exports = new LocalizationManager();
