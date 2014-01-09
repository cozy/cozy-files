(function(/*! Brunch !*/) {
  'use strict';

  var globals = typeof window !== 'undefined' ? window : global;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};

  var has = function(object, name) {
    return ({}).hasOwnProperty.call(object, name);
  };

  var expand = function(root, name) {
    var results = [], parts, part;
    if (/^\.\.?(\/|$)/.test(name)) {
      parts = [root, name].join('/').split('/');
    } else {
      parts = name.split('/');
    }
    for (var i = 0, length = parts.length; i < length; i++) {
      part = parts[i];
      if (part === '..') {
        results.pop();
      } else if (part !== '.' && part !== '') {
        results.push(part);
      }
    }
    return results.join('/');
  };

  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function(name) {
      var dir = dirname(path);
      var absolute = expand(dir, name);
      return globals.require(absolute);
    };
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    definition(module.exports, localRequire(name), module);
    var exports = cache[name] = module.exports;
    return exports;
  };

  var require = function(name) {
    var path = expand(name, '.');

    if (has(cache, path)) return cache[path];
    if (has(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has(cache, dirIndex)) return cache[dirIndex];
    if (has(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '"');
  };

  var define = function(bundle, fn) {
    if (typeof bundle === 'object') {
      for (var key in bundle) {
        if (has(bundle, key)) {
          modules[key] = bundle[key];
        }
      }
    } else {
      modules[bundle] = fn;
    }
  };

  globals.require = require;
  globals.require.define = define;
  globals.require.register = define;
  globals.require.brunch = true;
})();

window.require.register("application", function(exports, require, module) {
  var BreadcrumbsManager, File, FileCollection, FolderView;

  FileCollection = require('./collections/files');

  BreadcrumbsManager = require("./collections/breadcrumbs");

  File = require('./models/file');

  FolderView = require('./views/folder');

  module.exports = {
    initialize: function() {
      var Router, el;
      Router = require('router');
      this.router = new Router();
      this.breadcrumbs = new BreadcrumbsManager();
      this.root = new File({
        id: "root",
        path: "",
        name: "",
        type: "folder"
      });
      this.folderView = new FolderView({
        model: this.root,
        breadcrumbs: this.breadcrumbs
      });
      el = this.folderView.render().$el;
      $('body').append(el);
      Backbone.history.start();
      window.app = this;
      if (typeof Object.freeze === 'function') {
        return Object.freeze(this);
      }
    }
  };
  
});
window.require.register("collections/breadcrumbs", function(exports, require, module) {
  var BreadcrumbsManager, File, client, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  File = require('../models/file');

  client = require("../helpers/client");

  module.exports = BreadcrumbsManager = (function(_super) {
    __extends(BreadcrumbsManager, _super);

    function BreadcrumbsManager() {
      _ref = BreadcrumbsManager.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    BreadcrumbsManager.prototype.model = File;

    BreadcrumbsManager.prototype.add = function(folder) {
      return BreadcrumbsManager.__super__.add.call(this, folder, {
        sort: false
      });
    };

    BreadcrumbsManager.prototype.push = function(folder) {
      var found, path, treatment,
        _this = this;
      if ((this.length === 1) && (this.at(0) === this.root) && (folder !== this.root) && (folder.get("path") !== "") && (folder.get("type") === "folder")) {
        path = folder.get("path").split("/");
        path = path.slice(1, path.length);
        console.log("direct access", path);
        console.log("direct access", folder.get("path"));
        return client.get("folder/tree/" + folder.id, {
          success: function(data) {
            console.log("OK", data);
            _this.add(data, {
              sort: false
            });
            return _this.add(folder, {
              sort: false
            });
          },
          error: function(err) {
            return console.log("err", err);
          }
        });
      } else {
        if (this.get(folder)) {
          found = false;
          treatment = function(model, callback) {
            if (!found) {
              if (model.id === folder.id) {
                found = true;
              }
              return callback(null, [model]);
            } else {
              return callback(null);
            }
          };
          return async.concatSeries(this.models, treatment, function(err, folders) {
            if (err) {
              return console.log(err);
            } else {
              return _this.reset(folders, {
                sort: false
              });
            }
          });
        } else {
          return this.add(folder, {
            sort: false
          });
        }
      }
    };

    BreadcrumbsManager.prototype.setRoot = function(root) {
      this.reset();
      this.root = root;
      return this.add(root);
    };

    BreadcrumbsManager.prototype.popAll = function() {
      return this.setRoot(this.root);
    };

    return BreadcrumbsManager;

  })(Backbone.Collection);
  
});
window.require.register("collections/files", function(exports, require, module) {
  var File, FileCollection, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  File = require('../models/file');

  module.exports = FileCollection = (function(_super) {
    __extends(FileCollection, _super);

    function FileCollection() {
      _ref = FileCollection.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    FileCollection.prototype.model = File;

    FileCollection.prototype.order = "asc";

    FileCollection.prototype.url = 'files';

    FileCollection.prototype.comparator = function(o1, o2) {
      var n1, n2, sort, t1, t2;
      console.log("comparator: " + o1 + ", " + o2);
      n1 = o1.get("name").toLocaleLowerCase();
      n2 = o2.get("name").toLocaleLowerCase();
      t1 = o1.get("type");
      t2 = o2.get("type");
      sort = this.order === "asc" ? -1 : 1;
      if (t1 === t2) {
        if (n1 > n2) {
          return -sort;
        }
        if (n1 < n2) {
          return sort;
        }
        return 0;
      } else if (t1 === "file") {
        return -sort;
      } else {
        return sort;
      }
    };

    return FileCollection;

  })(Backbone.Collection);
  
});
window.require.register("helpers/client", function(exports, require, module) {
  exports.request = function(type, url, data, callbacks) {
    return $.ajax({
      type: type,
      url: url,
      data: data,
      success: callbacks.success,
      error: callbacks.error
    });
  };

  exports.get = function(url, callbacks) {
    return exports.request("GET", url, null, callbacks);
  };

  exports.post = function(url, data, callbacks) {
    return exports.request("POST", url, data, callbacks);
  };

  exports.put = function(url, data, callbacks) {
    return exports.request("PUT", url, data, callbacks);
  };

  exports.del = function(url, callbacks) {
    return exports.request("DELETE", url, null, callbacks);
  };
  
});
window.require.register("helpers/socket", function(exports, require, module) {
  var File, SocketListener, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  File = require('../models/file');

  module.exports = SocketListener = (function(_super) {
    __extends(SocketListener, _super);

    function SocketListener() {
      _ref = SocketListener.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    SocketListener.prototype.models = {
      'file': File,
      'folder': File
    };

    SocketListener.prototype.events = ['file.create', 'file.update', 'file.delete', 'folder.create', 'folder.update', 'folder.delete'];

    SocketListener.prototype.isInCurrentFolder = function(model) {
      var cwd, mwd;
      cwd = app.folderView.model.repository();
      mwd = model.get("path");
      return mwd === cwd;
    };

    SocketListener.prototype.onRemoteCreate = function(model) {
      if (this.isInCurrentFolder(model)) {
        console.log("remote create");
        console.log(model);
        if (!(this.collection.get(model.get("id")))) {
          return this.collection.add(model, {
            merge: true
          });
        }
      }
    };

    SocketListener.prototype.onRemoteDelete = function(model) {
      if (this.isInCurrentFolder(model)) {
        console.log("remote delete");
        console.log(model);
        return this.collection.remove(model);
      }
    };

    SocketListener.prototype.onRemoteUpdate = function(model, collection) {
      if (this.isInCurrentFolder(model)) {
        console.log("remote update");
        console.log(model);
        return collection.add(model, {
          merge: true
        });
      }
    };

    SocketListener.prototype.process = function(event) {
      var doctype, id, model, operation,
        _this = this;
      doctype = event.doctype, operation = event.operation, id = event.id;
      console.log("received: " + operation + ":" + doctype);
      switch (operation) {
        case 'create':
          model = new this.models[doctype]({
            id: id,
            type: doctype
          });
          return model.fetch({
            success: function(fetched) {
              fetched.set({
                type: doctype
              });
              return _this.onRemoteCreate(fetched);
            }
          });
        case 'update':
          return this.collections.forEach(function(collection) {
            if (!(model = collection.get(id))) {
              return;
            }
            return model.fetch({
              success: function(fetched) {
                if (fetched.changedAttributes()) {
                  fetched.set({
                    type: doctype
                  });
                  return _this.onRemoteUpdate(fetched, collection);
                }
              }
            });
          });
        case 'delete':
          return this.collections.forEach(function(collection) {
            if (!(model = collection.get(id))) {
              return;
            }
            return _this.onRemoteDelete(model, collection);
          });
      }
    };

    return SocketListener;

  })(CozySocketListener);
  
});
window.require.register("initialize", function(exports, require, module) {
  var app;

  app = require('application');

  $(function() {
    var initializeLocale, locale;
    jQuery.event.props.push('dataTransfer');
    $.fn.spin = function(opts, color) {
      var nullapp, presets;
      presets = {
        tiny: {
          lines: 8,
          length: 2,
          width: 2,
          radius: 3
        },
        small: {
          lines: 8,
          length: 1,
          width: 2,
          radius: 5
        },
        large: {
          lines: 10,
          length: 8,
          width: 4,
          radius: 8
        }
      };
      if (Spinner) {
        return this.each(function() {
          var $this, spinner;
          $this = $(this);
          spinner = $this.data("spinner");
          if (spinner != null) {
            spinner.stop();
            return $this.data("spinner", null);
          } else if (opts !== false) {
            if (typeof opts === "string") {
              if (opts in presets) {
                opts = presets[opts];
              } else {
                opts = {};
              }
              if (color) {
                opts.color = color;
              }
            }
            spinner = new Spinner($.extend({
              color: $this.css("color")
            }, opts));
            spinner.spin(this);
            return $this.data("spinner", spinner);
          }
        });
      } else {
        console.log("Spinner class not available.");
        return nullapp = require('application');
      }
    };
    locale = "en";
    $.ajax("cozy-locale.json", {
      success: function(data) {
        locale = data.locale;
        return initializeLocale(locale);
      },
      error: function() {
        return initializeLocale(locale);
      }
    });
    return initializeLocale = function(locale) {
      var err, locales, polyglot;
      locales = {};
      try {
        locales = require("locales/" + locale);
      } catch (_error) {
        err = _error;
        locales = require("locales/en");
      }
      polyglot = new Polyglot();
      polyglot.extend(locales);
      window.t = polyglot.t.bind(polyglot);
      return app.initialize();
    };
  });
  
});
window.require.register("lib/app_helpers", function(exports, require, module) {
  (function() {
    return (function() {
      var console, dummy, method, methods, _results;
      console = window.console = window.console || {};
      method = void 0;
      dummy = function() {};
      methods = 'assert,count,debug,dir,dirxml,error,exception,\
                   group,groupCollapsed,groupEnd,info,log,markTimeline,\
                   profile,profileEnd,time,timeEnd,trace,warn'.split(',');
      _results = [];
      while (method = methods.pop()) {
        _results.push(console[method] = console[method] || dummy);
      }
      return _results;
    })();
  })();
  
});
window.require.register("lib/base_view", function(exports, require, module) {
  var BaseView, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = BaseView = (function(_super) {
    __extends(BaseView, _super);

    function BaseView() {
      _ref = BaseView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    BaseView.prototype.template = function() {};

    BaseView.prototype.initialize = function() {};

    BaseView.prototype.getRenderData = function() {
      var _ref1;
      return {
        model: (_ref1 = this.model) != null ? _ref1.toJSON() : void 0
      };
    };

    BaseView.prototype.render = function() {
      this.beforeRender();
      this.$el.html(this.template(this.getRenderData()));
      this.afterRender();
      return this;
    };

    BaseView.prototype.beforeRender = function() {};

    BaseView.prototype.afterRender = function() {};

    BaseView.prototype.destroy = function() {
      this.undelegateEvents();
      this.$el.removeData().unbind();
      this.remove();
      return Backbone.View.prototype.remove.call(this);
    };

    return BaseView;

  })(Backbone.View);
  
});
window.require.register("lib/view_collection", function(exports, require, module) {
  var BaseView, ViewCollection, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseView = require('lib/base_view');

  module.exports = ViewCollection = (function(_super) {
    __extends(ViewCollection, _super);

    function ViewCollection() {
      this.removeItem = __bind(this.removeItem, this);
      this.addItem = __bind(this.addItem, this);
      _ref = ViewCollection.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ViewCollection.prototype.itemview = null;

    ViewCollection.prototype.views = {};

    ViewCollection.prototype.template = function() {
      return '';
    };

    ViewCollection.prototype.itemViewOptions = function() {};

    ViewCollection.prototype.collectionEl = null;

    ViewCollection.prototype.onChange = function() {
      return this.$el.toggleClass('empty', _.size(this.views) === 0);
    };

    ViewCollection.prototype.appendView = function(view) {
      return this.$collectionEl.append(view.el);
    };

    ViewCollection.prototype.initialize = function() {
      var collectionEl;
      ViewCollection.__super__.initialize.apply(this, arguments);
      this.views = {};
      this.listenTo(this.collection, "reset", this.onReset);
      this.listenTo(this.collection, "add", this.addItem);
      this.listenTo(this.collection, "remove", this.removeItem);
      if (this.collectionEl == null) {
        return collectionEl = el;
      }
    };

    ViewCollection.prototype.render = function() {
      var id, view, _ref1;
      _ref1 = this.views;
      for (id in _ref1) {
        view = _ref1[id];
        view.$el.detach();
      }
      return ViewCollection.__super__.render.apply(this, arguments);
    };

    ViewCollection.prototype.afterRender = function() {
      var id, view, _ref1;
      this.$collectionEl = $(this.collectionEl);
      _ref1 = this.views;
      for (id in _ref1) {
        view = _ref1[id];
        this.appendView(view.$el);
      }
      this.onReset(this.collection);
      return this.onChange(this.views);
    };

    ViewCollection.prototype.remove = function() {
      this.onReset([]);
      return ViewCollection.__super__.remove.apply(this, arguments);
    };

    ViewCollection.prototype.onReset = function(newcollection) {
      var id, view, _ref1;
      _ref1 = this.views;
      for (id in _ref1) {
        view = _ref1[id];
        view.remove();
      }
      return newcollection.forEach(this.addItem);
    };

    ViewCollection.prototype.addItem = function(model) {
      var options, view;
      options = _.extend({}, {
        model: model
      }, this.itemViewOptions(model));
      view = new this.itemview(options);
      this.views[model.cid] = view.render();
      this.appendView(view);
      return this.onChange(this.views);
    };

    ViewCollection.prototype.removeItem = function(model) {
      this.views[model.cid].remove();
      delete this.views[model.cid];
      return this.onChange(this.views);
    };

    return ViewCollection;

  })(BaseView);
  
});
window.require.register("locales/en", function(exports, require, module) {
  module.exports = {
    "modal error": "Error",
    "modal ok": "OK",
    "modal error get files": "Error getting files from server",
    "modal error get folders": "Error getting folders from server",
    "modal error empty name": "The name can't be empty",
    "modal error file invalid": "doesn't seem to be a valid file",
    "breadcrumbs search title": "Search",
    "modal error file exists": "Sorry, a file or folder having this name already exists",
    "modal error file upload": "File could not be sent to server",
    "modal error folder create": "Folder could not be created",
    "modal error folder exists": "Sorry, a file or folder having this name already exists",
    "modal are you sure": "Are you sure ?",
    "modal delete msg": "Deleting cannot be undone",
    "modal delete ok": "Delete",
    "modal cancel": "cancel",
    "modal delete error": "cancel",
    "modal error in use": "Name already in use",
    "modal error rename": "Name could not be changed",
    "modal error empty name": "Name can't be ampty",
    "modal shared file link title": "Share this file on the internet",
    "modal shared file link msg": "You can use this address to let others download this file:",
    "modal share file send msg": "If you want to send people notifications, type their emails here (separated by commas):",
    "modal shared folder link title": "Share this folder on the internet",
    "modal shared folder link msg": "You can use this address to let others download an archive with this folder:",
    "modal share folder send msg": "If you want to send people notifications, type their emails here (separated by commas):",
    "modal share send btn": "Share",
    "modal share error": "There was an error sharing this file",
    "file edit save": "Save",
    "file edit cancel": "cancel",
    "upload caption": "Upload a new file",
    "upload msg": "Choose the file to upload:",
    "upload close": "Close",
    "upload send": "Add",
    "upload button": "Upload a file here",
    "new folder caption": "Add a new folder",
    "new folder msg": "Enter the folder's name:",
    "new folder close": "Close",
    "new folder send": "Create",
    "new folder button": "Create a new folder"
  };
  
});
window.require.register("locales/fr", function(exports, require, module) {
  module.exports = {
    "modal error": "Erreur",
    "modal ok": "OK",
    "modal error get files": "Une erreur s'est produite en récupérant les fichiers du serveur",
    "modal error get folders": "Une erreur s'est produite en récupérant les dossiers du serveur",
    "modal error empty name": "Le nom ne peut pas être vide",
    "modal error file invalid": "Le fichier ne parait pas être valide",
    "breadcrumbs search title": "Recherche",
    "modal error file exists": "Désolé, un fichier ou un dossier a déjà le même nom",
    "modal error file upload": "Le fichier n'a pas pu être envoyé au serveur",
    "modal error folder create": "Le dossier n'a pas pu être créé",
    "modal error folder exists": "Désolé, un fichier ou un dossier a déjà le même nom",
    "modal are you sure": "Etes-vous sûr ?",
    "modal delete msg": "La suppression ne pourra pas être annulée",
    "modal delete ok": "Supprimer",
    "modal cancel": "Annuler",
    "modal delete error": "Annuler",
    "modal error in use": "Ce nom est déjà utilisé",
    "modal error rename": "Le nom n'a pas pu être modifié",
    "modal error empty name": "Le nom du dossier ne peut pas être vide",
    "modal shared file link title": "Partage d'un fichier",
    "modal shared file link msg": "Vous pouvez utiliser cette adresse pour permettre aux personnes désirées de télécharger le fichier :",
    "modal share file send msg": "Si vous souhaitez envoyer ce lien par mails, entrez les adresses mails ici (séparé par une virgule) :",
    "modal shared folder link title": "Partage d'un dossier",
    "modal shared folder link msg": "Vous pouvez utiliser cette adresse pour permettre aux personnes désirées de télécharger le dossier :",
    "modal share folder send msg": "Si vous souhaitez envoyer ce lien par mails, entrez les adresses mails ici (séparé par une virgule) :",
    "modal share send btn": "Partager",
    "modal share error": "Une erreur s'est produite pendant le partage",
    "file edit save": "Sauvegarder",
    "file edit cancel": "Annuler",
    "upload caption": "Télécharger un fichier",
    "upload msg": "Choisir un fichier à télécharger :",
    "upload close": "Annuler",
    "upload send": "Ajouter",
    "upload button": "Télécharger un fichier",
    "new folder caption": "Créer un nouveau dossier",
    "new folder msg": "Entrer le nom du dossier :",
    "new folder close": "Annuler",
    "new folder send": "Créer",
    "new folder button": "Créer un nouveau fichier"
  };
  
});
window.require.register("models/file", function(exports, require, module) {
  var File, client, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  client = require("../helpers/client");

  module.exports = File = (function(_super) {
    __extends(File, _super);

    function File() {
      _ref = File.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    File.prototype.sync = function(method, model, options) {
      var progress;
      progress = function(e) {
        return model.trigger('progress', e);
      };
      _.extend(options, {
        xhr: function() {
          var xhr;
          xhr = $.ajaxSettings.xhr();
          if (xhr instanceof window.XMLHttpRequest) {
            xhr.addEventListener('progress', progress, false);
          }
          if (xhr.upload) {
            xhr.upload.addEventListener('progress', progress, false);
          }
          return xhr;
        }
      });
      return Backbone.sync.apply(this, arguments);
    };

    File.prototype.urlRoot = function() {
      if (this.get("type") === "folder") {
        return 'folders/';
      } else if (this.get("type") === "search") {
        return 'search/';
      } else {
        return 'files/';
      }
    };

    File.prototype.validate = function() {
      var errors;
      errors = [];
      if (!this.get("name") || this.get("name") === "") {
        errors.push({
          field: 'name',
          value: "A name must be set."
        });
      }
      if (errors.length > 0) {
        return errors;
      }
    };

    File.prototype.prepareCallbacks = function(callbacks, presuccess, preerror) {
      var error, success, _ref1,
        _this = this;
      _ref1 = callbacks || {}, success = _ref1.success, error = _ref1.error;
      if (presuccess == null) {
        presuccess = function(data) {
          return _this.set(data.app);
        };
      }
      this.trigger('request', this, null, callbacks);
      callbacks.success = function(data) {
        if (presuccess) {
          presuccess(data);
        }
        _this.trigger('sync', _this, null, callbacks);
        if (success) {
          return success(data);
        }
      };
      return callbacks.error = function(jqXHR) {
        if (preerror) {
          preerror(jqXHR);
        }
        _this.trigger('error', _this, jqXHR, {});
        if (error) {
          return error(jqXHR);
        }
      };
    };

    File.prototype.repository = function() {
      var rep;
      rep = this.get("path") + "/" + this.get("name");
      if (rep === "/") {
        rep = "";
      }
      return rep;
    };

    File.prototype.endpoint = function() {
      if (this.get("type") === "folder") {
        return "foldershare";
      } else {
        return "fileshare";
      }
    };

    File.prototype.findFiles = function(callbacks) {
      this.prepareCallbacks(callbacks);
      return client.post("" + (this.urlRoot()) + "files", {
        id: this.id
      }, callbacks);
    };

    File.prototype.findFolders = function(callbacks) {
      this.prepareCallbacks(callbacks);
      return client.post("" + (this.urlRoot()) + "folders", {
        id: this.id
      }, callbacks);
    };

    File.prototype.getZip = function(file, callbacks) {
      this.prepareCallbacks(callbacks);
      return client.post("" + (this.urlRoot()) + this.id + "/zip/" + this.name, callbacks);
    };

    File.prototype.getAttachment = function(file, callbacks) {
      this.prepareCallbacks(callbacks);
      return client.post("" + (this.urlRoot()) + this.id + "/getAttachment/" + this.name, callbacks);
    };

    return File;

  })(Backbone.Model);
  
});
window.require.register("router", function(exports, require, module) {
  var File, FolderView, Router, app, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  app = require('application');

  FolderView = require('./views/folder');

  File = require('./models/file');

  module.exports = Router = (function(_super) {
    __extends(Router, _super);

    function Router() {
      _ref = Router.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Router.prototype.routes = {
      '': 'main',
      'folders/:folderid': 'folder',
      'search/:query': 'search'
    };

    Router.prototype.main = function() {
      return app.folderView.changeActiveFolder(app.root);
    };

    Router.prototype.folder = function(id) {
      var folder,
        _this = this;
      folder = new File({
        id: id,
        type: "folder"
      });
      return folder.fetch({
        success: function(data) {
          folder.set(data);
          return app.folderView.changeActiveFolder(folder);
        }
      });
    };

    Router.prototype.search = function(query) {
      var folder;
      folder = new File({
        id: query,
        type: "search",
        name: "Search '" + query + "'"
      });
      return app.folderView.changeActiveFolder(folder);
    };

    return Router;

  })(Backbone.Router);
  
});
window.require.register("views/breadcrumbs", function(exports, require, module) {
  var BaseView, BreadcrumbsView,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseView = require('../lib/base_view');

  module.exports = BreadcrumbsView = (function(_super) {
    __extends(BreadcrumbsView, _super);

    BreadcrumbsView.prototype.itemview = require('./templates/breadcrumbs_element');

    BreadcrumbsView.prototype.tagName = "ul";

    function BreadcrumbsView(collection) {
      this.collection = collection;
      BreadcrumbsView.__super__.constructor.call(this);
    }

    BreadcrumbsView.prototype.initialize = function() {
      this.listenTo(this.collection, "reset", this.render);
      this.listenTo(this.collection, "add", this.render);
      return this.listenTo(this.collection, "remove", this.render);
    };

    BreadcrumbsView.prototype.render = function() {
      var folder, _i, _len, _ref;
      this.$el.html("");
      _ref = this.collection.models;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        folder = _ref[_i];
        this.$el.append(this.itemview({
          model: folder
        }));
      }
      return this;
    };

    return BreadcrumbsView;

  })(BaseView);
  
});
window.require.register("views/file", function(exports, require, module) {
  var BaseView, FileView, ModalShareView, ModalView, client, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseView = require('../lib/base_view');

  ModalView = require("./modal");

  ModalShareView = require("./modal_share");

  client = require("../helpers/client");

  module.exports = FileView = (function(_super) {
    __extends(FileView, _super);

    function FileView() {
      this.onKeyPress = __bind(this.onKeyPress, this);
      _ref = FileView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    FileView.prototype.className = 'folder-row';

    FileView.prototype.tagName = 'tr';

    FileView.prototype.templateNormal = require('./templates/file');

    FileView.prototype.templateEdit = require('./templates/file_edit');

    FileView.prototype.templateSearch = require('./templates/file_search');

    FileView.prototype.events = {
      'click a.file-delete': 'onDeleteClicked',
      'click a.file-share': 'onShare',
      'click a.file-edit': 'onEditClicked',
      'click a.file-edit-save': 'onSaveClicked',
      'click a.file-edit-cancel': 'render',
      'keydown input': 'onKeyPress'
    };

    FileView.prototype.template = function(args) {
      if (app.folderView.model.get("type") === "search") {
        return this.templateSearch(args);
      } else {
        return this.templateNormal(args);
      }
    };

    FileView.prototype.initialize = function() {
      return this.listenTo(this.model, 'change', this.render);
    };

    FileView.prototype.onDeleteClicked = function() {
      var _this = this;
      return new ModalView(t("modal are you sure"), t("modal delete msg"), t("modal delete ok"), t("modal cancel"), function(confirm) {
        if (confirm) {
          return _this.model.destroy({
            error: function() {
              return new ModalView(t("modal error"), t("modal delete error"), t("modal ok"));
            }
          });
        }
      });
    };

    FileView.prototype.onEditClicked = function() {
      var width;
      width = this.$(".caption").width() + 10;
      this.$el.html(this.templateEdit({
        model: this.model.toJSON()
      }));
      this.$(".file-edit-name").width(width);
      return this.$(".file-edit-name").focus();
    };

    FileView.prototype.onShare = function() {
      var _this = this;
      return client.get("" + (this.model.endpoint()) + "/" + this.model.id, {
        success: function(data) {
          console.log(data);
          return new ModalShareView({
            url: data.url,
            model: _this.model
          });
        },
        error: function(data) {
          console.log(data);
          return new ModalView(t("modal error"), t("modal share error"), t("modal ok"));
        }
      });
    };

    FileView.prototype.onSaveClicked = function() {
      var name,
        _this = this;
      name = this.$('.file-edit-name').val();
      if (name && name !== "") {
        return this.model.save({
          name: name
        }, {
          wait: true,
          success: function(data) {
            return _this.render();
          },
          error: function(model, err) {
            console.log(err);
            if (err.status === 400) {
              return new ModalView(t("modal error"), t("modal error in use"), t("modal ok"));
            } else {
              return new ModalView(t("modal error"), t("modal error rename"), t("modal ok"));
            }
          }
        });
      } else {
        return new ModalView(t("modal error"), t("modal error empty name"), t("modal ok"));
      }
    };

    FileView.prototype.onKeyPress = function(e) {
      if (e.keyCode === 13) {
        return this.onSaveClicked();
      }
    };

    return FileView;

  })(BaseView);
  
});
window.require.register("views/files", function(exports, require, module) {
  var File, FileCollection, FileView, FilesView, ModalView, ProgressbarView, SocketListener, ViewCollection, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ViewCollection = require('../lib/view_collection');

  FileView = require('./file');

  ProgressbarView = require("./progressbar");

  ModalView = require("./modal");

  File = require('../models/file');

  FileCollection = require('../collections/files');

  SocketListener = require('../helpers/socket');

  module.exports = FilesView = (function(_super) {
    __extends(FilesView, _super);

    function FilesView() {
      this.upload = __bind(this.upload, this);
      this.addFile = __bind(this.addFile, this);
      _ref = FilesView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    FilesView.prototype.template = require('./templates/files');

    FilesView.prototype.itemview = FileView;

    FilesView.prototype.collectionEl = '#table-items-body';

    FilesView.views = {};

    FilesView.prototype.initialize = function(collection, model) {
      this.collection = collection;
      this.model = model;
      FilesView.__super__.initialize.call(this);
      this.listenTo(this.collection, "sort", this.render);
      this.listenTo(this.collection, "remove", this.render);
      this.listenTo(this.collection, "add", this.render);
      this.socket = new SocketListener();
      return this.socket.watch(this.collection);
    };

    FilesView.prototype.addFile = function(attach) {
      var file, fileAttributes, found, progress;
      found = this.collection.findWhere({
        name: attach.name
      });
      if (!found) {
        fileAttributes = {
          'name': attach.name,
          'path': this.model.repository(),
          'type': "file",
          'lastModification': attach.lastModifiedDate
        };
        file = new File(fileAttributes);
        file.file = attach;
        progress = new ProgressbarView(file);
        $("#dialog-upload-file .modal-body").append(progress.render().el);
        return this.upload(file);
      } else {
        return new ModalView(t("modal error"), "" + (t('modal error file exists')) + ": " + attach.name, t("modal ok"));
      }
    };

    FilesView.prototype.upload = function(file) {
      var formdata,
        _this = this;
      formdata = new FormData();
      formdata.append('cid', file.cid);
      formdata.append('name', file.get('name'));
      formdata.append('path', file.get('path'));
      formdata.append('file', file.file);
      formdata.append('lastModification', file.get('lastModification'));
      return file.save(null, {
        contentType: false,
        data: formdata,
        success: function(data) {
          return _this.collection.add(file, {
            merge: true
          });
        },
        error: function() {
          return new ModalView(t("modal error"), t("modal error file upload"), t("modal ok"));
        }
      });
    };

    FilesView.prototype.addFolder = function(folder) {
      var found,
        _this = this;
      found = this.collection.findWhere({
        name: folder.get("name")
      });
      if (!found) {
        return folder.save(null, {
          success: function(data) {
            return _this.collection.add(folder);
          },
          error: function(error) {
            return new ModalView(t("modal error"), t("modal error folder create"), t("modal ok"));
          }
        });
      } else {
        return new ModalView(t("modal error"), t("modal error folder exists"), t("modal ok"));
      }
    };

    return FilesView;

  })(ViewCollection);
  
});
window.require.register("views/folder", function(exports, require, module) {
  var BaseView, BreadcrumbsView, File, FileCollection, FilesView, FolderView, ModalView, ProgressbarView, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseView = require('../lib/base_view');

  FilesView = require('./files');

  BreadcrumbsView = require("./breadcrumbs");

  ProgressbarView = require("./progressbar");

  ModalView = require("./modal");

  File = require('../models/file');

  FileCollection = require('../collections/files');

  module.exports = FolderView = (function(_super) {
    __extends(FolderView, _super);

    function FolderView() {
      this.onSeachKeyPress = __bind(this.onSeachKeyPress, this);
      this.onDragAndDrop = __bind(this.onDragAndDrop, this);
      this.onAddFile = __bind(this.onAddFile, this);
      this.onAddFolder = __bind(this.onAddFolder, this);
      _ref = FolderView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    FolderView.prototype.template = require('./templates/folder');

    FolderView.prototype.events = function() {
      return {
        'click a#button-new-folder': 'prepareNewFolder',
        'click #new-folder-send': 'onAddFolder',
        'click #upload-file-send': 'onAddFile',
        'keyup input#search-box': 'onSeachKeyPress',
        'keyup input#inputName': 'onAddFolderEnter'
      };
    };

    FolderView.prototype.initialize = function(options) {
      var prevent,
        _this = this;
      this.model = options.model;
      this.breadcrumbs = options.breadcrumbs;
      this.breadcrumbs.setRoot(this.model);
      prevent = function(e) {
        e.preventDefault();
        return e.stopPropagation();
      };
      this.$el.on("dragover", prevent);
      this.$el.on("dragenter", prevent);
      return this.$el.on("drop", function(e) {
        return _this.onDragAndDrop(e);
      });
    };

    FolderView.prototype.getRenderData = function() {
      return {
        model: this.model
      };
    };

    FolderView.prototype.afterRender = function() {
      this.breadcrumbsView = new BreadcrumbsView(this.breadcrumbs);
      return this.$("#crumbs").append(this.breadcrumbsView.render().$el);
    };

    /*
        Display and re-render the contents of the folder
    */


    FolderView.prototype.changeActiveFolder = function(folder) {
      var _this = this;
      this.model = folder;
      this.breadcrumbs.push(folder);
      if (folder.get("type") === "folder") {
        this.$("#upload-buttons").show();
      } else {
        this.$("#upload-buttons").hide();
      }
      return this.model.findFiles({
        success: function(files) {
          var file, _i, _len;
          for (_i = 0, _len = files.length; _i < _len; _i++) {
            file = files[_i];
            file.type = "file";
          }
          return _this.model.findFolders({
            success: function(folders) {
              var _j, _len1, _ref1;
              for (_j = 0, _len1 = folders.length; _j < _len1; _j++) {
                folder = folders[_j];
                folder.type = "folder";
              }
              if (_this.filesCollection) {
                _this.stopListening(_this.filesCollection);
              }
              _this.filesCollection = new FileCollection(folders.concat(files));
              _this.listenTo(_this.filesCollection, "sync", _this.hideUploadForm);
              if (_this.filesList) {
                if ((_ref1 = _this.filesList) != null) {
                  _ref1.destroy();
                }
              }
              _this.filesList = new FilesView(_this.filesCollection, _this.model);
              _this.$('#files').html(_this.filesList.$el);
              return _this.filesList.render();
            },
            error: function(error) {
              console.log(error);
              return new ModalView(t("modal error"), t("modal error get folders"), t("modal ok"));
            }
          });
        },
        error: function(error) {
          console.log(error);
          return new ModalView(t("modal error"), t("modal error get files"), t("modal ok"));
        }
      });
    };

    /*
        Upload/ new folder
    */


    FolderView.prototype.prepareNewFolder = function() {
      var _this = this;
      return setTimeout(function() {
        return _this.$("#inputName").focus();
      }, 500);
    };

    FolderView.prototype.onAddFolderEnter = function(e) {
      if (e.keyCode === 13) {
        e.preventDefault();
        e.stopPropagation();
        return this.onAddFolder();
      }
    };

    FolderView.prototype.onAddFolder = function() {
      var folder;
      folder = new File({
        name: this.$('#inputName').val(),
        path: this.model.repository(),
        type: "folder"
      });
      console.log("creating folder " + folder);
      if (folder.validate()) {
        return new ModalView(t("modal error"), t("modal error empty name"), t("modal ok"));
      } else {
        this.filesList.addFolder(folder);
        return $('#dialog-new-folder').modal('hide');
      }
    };

    FolderView.prototype.onAddFile = function() {
      var attach, _i, _len, _ref1, _results;
      _ref1 = this.$('#uploader')[0].files;
      _results = [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        attach = _ref1[_i];
        _results.push(this.filesList.addFile(attach));
      }
      return _results;
    };

    FolderView.prototype.onDragAndDrop = function(e) {
      var atLeastOne, attach, _i, _len, _ref1;
      e.preventDefault();
      e.stopPropagation();
      console.log("Drag and drop");
      atLeastOne = false;
      _ref1 = e.dataTransfer.files;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        attach = _ref1[_i];
        if (attach.type === "") {
          new ModalView(t("modal error"), "" + attach.name + " " + (t('modal error file invalid')), t("modal ok"));
        } else {
          this.filesList.addFile(attach);
          atLeastOne = true;
        }
      }
      if (atLeastOne) {
        return $("#dialog-upload-file").modal("show");
      }
    };

    FolderView.prototype.hideUploadForm = function() {
      return $('#dialog-upload-file').modal('hide');
    };

    /*
        Search
    */


    FolderView.prototype.onSeachKeyPress = function(e) {
      var query;
      query = this.$('input#search-box').val();
      if (query !== "") {
        this.displaySearchResults(query);
        return app.router.navigate("search/" + query);
      } else {
        return this.changeActiveFolder(this.breadcrumbs.root);
      }
    };

    FolderView.prototype.displaySearchResults = function(query) {
      var data, search;
      this.breadcrumbs.popAll();
      data = {
        id: query,
        name: "" + (t('breadcrumbs search title')) + " '" + query + "'",
        type: "search"
      };
      search = new File(data);
      return this.changeActiveFolder(search);
    };

    return FolderView;

  })(BaseView);
  
});
window.require.register("views/modal", function(exports, require, module) {
  var BaseView, ModalView,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseView = require('../lib/base_view');

  module.exports = ModalView = (function(_super) {
    __extends(ModalView, _super);

    ModalView.prototype.template = require('./templates/modal');

    ModalView.prototype.value = 0;

    ModalView.prototype.events = {
      "click #modal-dialog-no": "onNo",
      "click #modal-dialog-yes": "onYes"
    };

    function ModalView(title, msg, yes, no, cb) {
      this.title = title;
      this.msg = msg;
      this.yes = yes;
      this.no = no;
      this.cb = cb;
      ModalView.__super__.constructor.call(this);
    }

    ModalView.prototype.initialize = function() {
      this.render();
      return this.$('#modal-dialog').modal('show');
    };

    ModalView.prototype.onYes = function() {
      var _this = this;
      if (this.cb) {
        this.cb(true);
      }
      this.$('#modal-dialog').modal('hide');
      return setTimeout(function() {
        return _this.destroy();
      }, 1000);
    };

    ModalView.prototype.onNo = function() {
      var _this = this;
      if (this.cb) {
        this.cb(false);
      }
      this.$('#modal-dialog').modal('hide');
      return setTimeout(function() {
        return _this.destroy();
      }, 1000);
    };

    ModalView.prototype.render = function() {
      this.$el.append(this.template({
        title: this.title,
        msg: this.msg,
        yes: this.yes,
        no: this.no
      }));
      $("body").append(this.el);
      return this;
    };

    return ModalView;

  })(BaseView);
  
});
window.require.register("views/modal_share", function(exports, require, module) {
  var BaseView, ModalShareView, ModalView, client, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseView = require('../lib/base_view');

  ModalView = require("./modal");

  client = require("../helpers/client");

  module.exports = ModalShareView = (function(_super) {
    __extends(ModalShareView, _super);

    function ModalShareView() {
      _ref = ModalShareView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ModalShareView.prototype.template = require('./templates/modal_share_file');

    ModalShareView.prototype.events = {
      "click #modal-dialog-share-send": "send"
    };

    ModalShareView.prototype.initialize = function(options) {
      console.log(options);
      this.url = options.url;
      this.model = options.model;
      if (this.model.get("type") === "folder") {
        this.template = require('./templates/modal_share_folder');
      }
      this.render();
      return this.$('#modal-dialog').modal('show');
    };

    ModalShareView.prototype.send = function() {
      var input, mails,
        _this = this;
      input = this.$('#modal-dialog-share-input').val();
      console.log(input);
      mails = input.replace(/\s+/g, ' ').replace(/\ /g, ',').replace(/\,+/g, ',').split(",");
      console.log(mails);
      return client.post("" + (this.model.endpoint()) + "/" + this.model.id + "/send", {
        users: mails
      }, {
        success: function(data) {
          _this.$('#modal-dialog').modal('hide');
          return setTimeout(function() {
            return _this.destroy();
          }, 1000);
        },
        error: function(data) {
          return new ModalView(t("modal error"), t("modal share error"), t("modal ok"));
        }
      });
    };

    ModalShareView.prototype.render = function() {
      this.$el.append(this.template({
        url: this.url
      }));
      $("body").append(this.el);
      return this;
    };

    return ModalShareView;

  })(BaseView);
  
});
window.require.register("views/progressbar", function(exports, require, module) {
  var BaseView, ProgressbarView,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseView = require('../lib/base_view');

  module.exports = ProgressbarView = (function(_super) {
    __extends(ProgressbarView, _super);

    ProgressbarView.prototype.className = 'progress';

    ProgressbarView.prototype.template = require('./templates/progressbar');

    ProgressbarView.prototype.value = 0;

    function ProgressbarView(model) {
      this.model = model;
      ProgressbarView.__super__.constructor.call(this);
    }

    ProgressbarView.prototype.initialize = function() {
      this.listenTo(this.model, 'progress', this.update);
      return this.listenTo(this.model, 'sync', this.destroy);
    };

    ProgressbarView.prototype.update = function(e) {
      var pc;
      pc = parseInt(e.loaded / e.total * 100);
      console.log("[Progress bar] : " + pc + " %");
      this.value = pc;
      return this.render();
    };

    ProgressbarView.prototype.getRenderData = function() {
      return {
        value: this.value
      };
    };

    return ProgressbarView;

  })(BaseView);
  
});
window.require.register("views/templates/breadcrumbs_element", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  if ( model.id == "root")
  {
  buf.push('<li><a href="#"><span class="glyphicon glyphicon-folder-open"></span></a></li>');
  }
  else
  {
  if ( model.attributes.type == "search")
  {
  buf.push('<li><a');
  buf.push(attrs({ 'href':("#search/" + (model.id) + "") }, {"href":true}));
  buf.push('>' + escape((interp = model.attributes.name) == null ? '' : interp) + '</a></li>');
  }
  else
  {
  buf.push('<li><a');
  buf.push(attrs({ 'href':("#folders/" + (model.id) + "") }, {"href":true}));
  buf.push('>' + escape((interp = model.attributes.name) == null ? '' : interp) + '</a></li>');
  }
  }
  }
  return buf.join("");
  };
});
window.require.register("views/templates/file", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  if ( model.type && model.type == "folder")
  {
  buf.push('<td><a');
  buf.push(attrs({ 'href':("#folders/" + (model.id) + ""), "class": ('img-folder') }, {"href":true}));
  buf.push('><img src="images/folder.png"/></a><a');
  buf.push(attrs({ 'href':("#folders/" + (model.id) + ""), "class": ('caption') + ' ' + ('btn') + ' ' + ('btn-link') }, {"href":true}));
  buf.push('>' + escape((interp = model.name) == null ? '' : interp) + '</a><div class="operations"><a class="file-delete"><span class="glyphicon glyphicon-remove-circle"> </span></a><a class="file-edit"><span class="glyphicon glyphicon-edit"> </span></a><a');
  buf.push(attrs({ 'href':("folders/" + (model.id) + "/zip/" + (model.name) + ""), 'target':("_blank") }, {"href":true,"target":true}));
  buf.push('><span class="glyphicon glyphicon-cloud-download"> </span></a><a class="file-share"><span class="glyphicon glyphicon-share-alt"></span></a></div></td><td></td><td></td><td></td>');
  }
  else
  {
  buf.push('<td><a');
  buf.push(attrs({ 'href':("files/" + (model.id) + "/attach/" + (model.name) + ""), 'target':("_blank"), "class": ('img-file') }, {"href":true,"target":true}));
  buf.push('>');
  if ( model.mime == "application/pdf")
  {
  buf.push('<img src="images/pdf.png"/>');
  }
  else if ( model.mime == "image/jpeg")
  {
  buf.push('<img src="images/jpg.png"/>');
  }
  else if ( model.mime == "text/plain")
  {
  buf.push('<img src="images/txt.png"/>');
  }
  else
  {
  buf.push('<img src="images/file.png"/>');
  }
  buf.push('</a><a');
  buf.push(attrs({ 'href':("files/" + (model.id) + "/attach/" + (model.name) + ""), 'target':("_blank"), "class": ('caption') + ' ' + ('btn') + ' ' + ('btn-link') }, {"href":true,"target":true}));
  buf.push('>' + escape((interp = model.name) == null ? '' : interp) + '</a><div class="operations"><a class="file-delete"><span class="glyphicon glyphicon-remove-circle"> </span></a><a class="file-edit"><span class="glyphicon glyphicon-edit"> </span></a><a');
  buf.push(attrs({ 'href':("files/" + (model.id) + "/download/" + (model.name) + ""), 'download':("" + (model.name) + "") }, {"href":true,"download":true}));
  buf.push('><span class="glyphicon glyphicon-cloud-download"> </span></a><a class="file-share"><span class="glyphicon glyphicon-share-alt"></span></a></div></td><td class="file-size">');
   options = {base: 2}
  buf.push('<span class="pull-left">' + escape((interp = filesize(model.size || 0, options)) == null ? '' : interp) + '</span></td><td class="file-type"><span class="pull-left">' + escape((interp = model.mime) == null ? '' : interp) + '</span></td><td class="file-date">');
  if ( model.lastModification)
  {
  buf.push('<span class="pull-right">' + escape((interp = moment(model.lastModification).calendar()) == null ? '' : interp) + '</span>');
  }
  buf.push('</td>');
  }
  }
  return buf.join("");
  };
});
window.require.register("views/templates/file_edit", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<td>');
  if ( model.type && model.type == "folder")
  {
  buf.push('<a class="img-folder"><img src="images/folder.png"/></a>');
  }
  else
  {
  buf.push('<span class="glyphicon glyphicon-file no-hover icon"></span>');
  }
  buf.push('<input');
  buf.push(attrs({ 'value':(model.name), "class": ('caption') + ' ' + ('file-edit-name') }, {"value":true}));
  buf.push('/><a class="btn btn-sm btn-cozy file-edit-save">' + escape((interp = t("file edit save")) == null ? '' : interp) + '</a><a class="btn btn-sm btn-link file-edit-cancel">' + escape((interp = t("file edit cancel")) == null ? '' : interp) + '</a></td><td></td><td class="file-date"><span class="pull-right">12:00 12/10/2013</span></td>');
  }
  return buf.join("");
  };
});
window.require.register("views/templates/file_search", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  if ( model.type && model.type == "folder")
  {
  buf.push('<td><a class="img-folder"><img src="images/folder.png"/></a><a');
  buf.push(attrs({ 'href':("#folders/" + (model.id) + ""), "class": ('caption') + ' ' + ('btn') + ' ' + ('btn-link') }, {"href":true}));
  buf.push('>' + escape((interp = model.name) == null ? '' : interp) + '</a><div class="operations"><a class="file-delete"><span class="glyphicon glyphicon-remove-circle"> </span></a><a class="file-edit"><span class="glyphicon glyphicon-edit"></span></a></div><p class="file-path">' + escape((interp = model.path) == null ? '' : interp) + '/' + escape((interp = model.name) == null ? '' : interp) + '</p></td><td></td><td></td><td></td>');
  }
  else
  {
  buf.push('<td><span class="glyphicon glyphicon-file no-hover icon"></span><a');
  buf.push(attrs({ 'href':("files/" + (model.id) + "/attach/" + (model.name) + ""), 'target':("_blank"), "class": ('caption') + ' ' + ('btn') + ' ' + ('btn-link') }, {"href":true,"target":true}));
  buf.push('>' + escape((interp = model.name) == null ? '' : interp) + '</a><div class="operations"><a class="file-delete"><span class="glyphicon glyphicon-remove-circle"> </span></a><a class="file-edit"><span class="glyphicon glyphicon-edit"> </span></a><a');
  buf.push(attrs({ 'href':("files/" + (model.id) + "/download/" + (model.name) + ""), 'download':("" + (model.name) + "") }, {"href":true,"download":true}));
  buf.push('><span class="glyphicon glyphicon-cloud-download"> </span></a><a class="file-share"><span class="glyphicon glyphicon-share-alt"></span></a></div><p class="file-path">' + escape((interp = model.path) == null ? '' : interp) + '/' + escape((interp = model.name) == null ? '' : interp) + '</p></td><td class="file-size">');
   options = {base: 2}
  buf.push('<span class="pull-left">' + escape((interp = filesize(model.size || 0, options)) == null ? '' : interp) + '</span></td><td class="file-type"><span class="pull-left">' + escape((interp = model.mime) == null ? '' : interp) + '</span></td><td class="file-date">');
  if ( model.lastModification)
  {
  buf.push('<span class="pull-right">' + escape((interp = moment(model.lastModification).calendar()) == null ? '' : interp) + '</span>');
  }
  buf.push('</td>');
  }
  }
  return buf.join("");
  };
});
window.require.register("views/templates/files", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<table id="table-items" class="table table-hover"><tbody id="table-items-body"></tbody></table>');
  }
  return buf.join("");
  };
});
window.require.register("views/templates/folder", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<div id="dialog-upload-file" class="modal fade"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button><h4 class="modal-title">' + escape((interp = t("upload caption")) == null ? '' : interp) + '</h4></div><div class="modal-body"><fieldset><div class="form-group"><label for="uploader">' + escape((interp = t("upload msg")) == null ? '' : interp) + '</label><input id="uploader" type="file" multiple="multiple"/></div></fieldset></div><div class="modal-footer"><button type="button" data-dismiss="modal" class="btn btn-link">' + escape((interp = t("upload close")) == null ? '' : interp) + '</button><button id="upload-file-send" type="button" class="btn btn-cozy-contrast">' + escape((interp = t("upload send")) == null ? '' : interp) + '</button></div></div></div></div><div id="dialog-new-folder" class="modal fade"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button><h4 class="modal-title">' + escape((interp = t("new folder caption")) == null ? '' : interp) + '</h4></div><div class="modal-body"><fieldset><div class="form-group"><label for="inputName">' + escape((interp = t("new folder msg")) == null ? '' : interp) + '</label><input id="inputName" type="text" class="form-control"/></div></fieldset></div><div class="modal-footer"><button type="button" data-dismiss="modal" class="btn btn-link">' + escape((interp = t("new folder close")) == null ? '' : interp) + '</button><button id="new-folder-send" type="button" class="btn btn-cozy">' + escape((interp = t("new folder send")) == null ? '' : interp) + '</button></div></div></div></div><div id="affixbar" data-spy="affix" data-offset-top="1"><div class="container"><div class="row"><div class="col-lg-12"><div class="pull-left"><input id="search-box" type="search"/></div><div id="upload-buttons" class="pull-right"><p class="pull-right"><a data-toggle="modal" data-target="#dialog-upload-file" class="btn btn-cozy-contrast"><span class="glyphicon glyphicon-upload"></span><span class="button-title-reponsive"> ' + escape((interp = t("upload button")) == null ? '' : interp) + '</span></a> <a id="button-new-folder" data-toggle="modal" data-target="#dialog-new-folder" class="btn btn-cozy"><span class="glyphicon glyphicon-plus-sign"></span><span class="button-title-reponsive"> ' + escape((interp = t("new folder button")) == null ? '' : interp) + '</span></a></p></div></div></div></div></div><div class="container"><div class="row content-shadow"><div id="content" class="col-lg-12"><div id="crumbs"></div><div id="files"></div></div></div></div>');
  }
  return buf.join("");
  };
});
window.require.register("views/templates/modal", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<div id="modal-dialog" class="modal fade"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button><h4 class="modal-title">' + escape((interp = title) == null ? '' : interp) + '</h4></div><div class="modal-body"><p>' + escape((interp = msg) == null ? '' : interp) + '</p></div><div class="modal-footer">');
  if ( no)
  {
  buf.push('<button id="modal-dialog-no" type="button" class="btn btn-link">' + escape((interp = no) == null ? '' : interp) + '</button>');
  }
  if ( yes)
  {
  buf.push('<button id="modal-dialog-yes" type="button" class="btn btn-cozy">' + escape((interp = yes) == null ? '' : interp) + '</button>');
  }
  buf.push('</div></div></div></div>');
  }
  return buf.join("");
  };
});
window.require.register("views/templates/modal_share_file", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<div id="modal-dialog" class="modal fade"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button><h4 class="modal-title">' + escape((interp = t('modal shared file link title')) == null ? '' : interp) + '</h4></div><div class="modal-body"><p>' + escape((interp = t('modal shared file link msg')) == null ? '' : interp) + '<input');
  buf.push(attrs({ 'value':(url), "class": ('form-control') }, {"value":true}));
  buf.push('/></p><p>' + escape((interp = t('modal share file send msg')) == null ? '' : interp) + '<input id="modal-dialog-share-input" type="text" class="form-control"/></p></div><div class="modal-footer"><button id="modal-dialog-share-send" type="button" class="btn btn-cozy">' + escape((interp = t('modal share send btn')) == null ? '' : interp) + '</button></div></div></div></div>');
  }
  return buf.join("");
  };
});
window.require.register("views/templates/modal_share_folder", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<div id="modal-dialog" class="modal fade"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button><h4 class="modal-title">' + escape((interp = t('modal shared folder link title')) == null ? '' : interp) + '</h4></div><div class="modal-body"><p>' + escape((interp = t('modal shared folder link msg')) == null ? '' : interp) + '<input');
  buf.push(attrs({ 'value':(url), "class": ('form-control') }, {"value":true}));
  buf.push('/></p><p>' + escape((interp = t('modal share folder send msg')) == null ? '' : interp) + '<input id="modal-dialog-share-input" type="text" class="form-control"/></p></div><div class="modal-footer"><button id="modal-dialog-share-send" type="button" class="btn btn-cozy">' + escape((interp = t('modal share send btn')) == null ? '' : interp) + '</button></div></div></div></div>');
  }
  return buf.join("");
  };
});
window.require.register("views/templates/progressbar", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<div class="progress progress-striped active"><div');
  buf.push(attrs({ 'role':("progressbar"), 'aria-valuenow':("" + (value) + ""), 'aria-valuemin':("0"), 'aria-valuemax':("100"), 'style':("width: " + (value) + "%"), "class": ('progress-bar') + ' ' + ('progress-bar-success') }, {"role":true,"aria-valuenow":true,"aria-valuemin":true,"aria-valuemax":true,"style":true}));
  buf.push('></div></div>');
  }
  return buf.join("");
  };
});
