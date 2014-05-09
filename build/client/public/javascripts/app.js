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
      return globals.require(absolute, path);
    };
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    cache[name] = module;
    definition(module.exports, localRequire(name), module);
    return module.exports;
  };

  var require = function(name, loaderPath) {
    var path = expand(name, '.');
    if (loaderPath == null) loaderPath = '/';

    if (has(cache, path)) return cache[path].exports;
    if (has(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has(cache, dirIndex)) return cache[dirIndex].exports;
    if (has(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '" from '+ '"' + loaderPath + '"');
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

  var list = function() {
    var result = [];
    for (var item in modules) {
      if (has(modules, item)) {
        result.push(item);
      }
    }
    return result;
  };

  globals.require = require;
  globals.require.define = define;
  globals.require.register = define;
  globals.require.list = list;
  globals.require.brunch = true;
})();
require.register("application", function(exports, require, module) {
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

;require.register("collections/breadcrumbs", function(exports, require, module) {
var BreadcrumbsManager, File, client,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

File = require('../models/file');

client = require("../helpers/client");

module.exports = BreadcrumbsManager = (function(_super) {
  __extends(BreadcrumbsManager, _super);

  function BreadcrumbsManager() {
    return BreadcrumbsManager.__super__.constructor.apply(this, arguments);
  }

  BreadcrumbsManager.prototype.model = File;

  BreadcrumbsManager.prototype.add = function(folder) {
    return BreadcrumbsManager.__super__.add.call(this, folder, {
      sort: false
    });
  };

  BreadcrumbsManager.prototype.push = function(folder) {
    var found, path, treatment;
    if ((this.length === 1) && (this.at(0) === this.root) && (folder !== this.root) && (folder.get("path") !== "") && (folder.get("type") === "folder")) {
      path = folder.get("path").split("/");
      path = path.slice(1, path.length);
      console.log("direct access", path);
      console.log("direct access", folder.get("path"));
      return client.get("folder/tree/" + folder.id, {
        success: (function(_this) {
          return function(data) {
            console.log("OK", data);
            _this.add(data, {
              sort: false
            });
            return _this.add(folder, {
              sort: false
            });
          };
        })(this),
        error: (function(_this) {
          return function(err) {
            return console.log("err", err);
          };
        })(this)
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
        return async.concatSeries(this.models, treatment, (function(_this) {
          return function(err, folders) {
            if (err) {
              return console.log(err);
            } else {
              return _this.reset(folders, {
                sort: false
              });
            }
          };
        })(this));
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

;require.register("collections/files", function(exports, require, module) {
var File, FileCollection,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

File = require('../models/file');

module.exports = FileCollection = (function(_super) {
  __extends(FileCollection, _super);

  function FileCollection() {
    return FileCollection.__super__.constructor.apply(this, arguments);
  }

  FileCollection.prototype.model = File;

  FileCollection.prototype.order = "incr";

  FileCollection.prototype.type = "name";

  FileCollection.prototype.url = 'files';

  FileCollection.prototype.comparator = function(o1, o2) {
    var n1, n2, sort, t1, t2;
    if (this.type === "name") {
      n1 = o1.get("name").toLocaleLowerCase();
      n2 = o2.get("name").toLocaleLowerCase();
    } else if (this.type === "lastModification") {
      n1 = new Date(o1.get("lastModification"));
      n2 = new Date(o2.get("lastModification"));
    } else {
      n1 = o1.get(this.type);
      n2 = o2.get(this.type);
    }
    t1 = o1.get("type");
    t2 = o2.get("type");
    sort = this.order === "incr" ? -1 : 1;
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

;require.register("helpers/client", function(exports, require, module) {
exports.request = function(type, url, data, callbacks) {
  return $.ajax({
    type: type,
    url: url,
    data: JSON.stringify(data),
    contentType: 'application/json; charset=utf-8',
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

;require.register("helpers/socket", function(exports, require, module) {
var File, SocketListener,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

File = require('../models/file');

module.exports = SocketListener = (function(_super) {
  __extends(SocketListener, _super);

  function SocketListener() {
    return SocketListener.__super__.constructor.apply(this, arguments);
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
    var doctype, id, model, operation;
    doctype = event.doctype, operation = event.operation, id = event.id;
    switch (operation) {
      case 'create':
        model = new this.models[doctype]({
          id: id,
          type: doctype
        });
        return model.fetch({
          success: (function(_this) {
            return function(fetched) {
              fetched.set({
                type: doctype
              });
              return _this.onRemoteCreate(fetched);
            };
          })(this)
        });
      case 'update':
        return this.collections.forEach((function(_this) {
          return function(collection) {
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
          };
        })(this));
      case 'delete':
        return this.collections.forEach((function(_this) {
          return function(collection) {
            if (!(model = collection.get(id))) {
              return;
            }
            return _this.onRemoteDelete(model, collection);
          };
        })(this));
    }
  };

  return SocketListener;

})(CozySocketListener);

});

;require.register("initialize", function(exports, require, module) {
var app;

app = require('application');

$(function() {
  var initializeLocale, locale;
  jQuery.event.props.push('dataTransfer');
  $.fn.spin = function(opts, color) {
    var nullapp, presets;
    presets = {
      tiny: {
        lines: 6,
        length: 1,
        width: 1,
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

;require.register("lib/app_helpers", function(exports, require, module) {
(function() {
  return (function() {
    var console, dummy, method, methods, _results;
    console = window.console = window.console || {};
    method = void 0;
    dummy = function() {};
    methods = 'assert,count,debug,dir,dirxml,error,exception, group,groupCollapsed,groupEnd,info,log,markTimeline, profile,profileEnd,time,timeEnd,trace,warn'.split(',');
    _results = [];
    while (method = methods.pop()) {
      _results.push(console[method] = console[method] || dummy);
    }
    return _results;
  })();
})();

});

;require.register("lib/base_view", function(exports, require, module) {
var BaseView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = BaseView = (function(_super) {
  __extends(BaseView, _super);

  function BaseView() {
    return BaseView.__super__.constructor.apply(this, arguments);
  }

  BaseView.prototype.template = function() {};

  BaseView.prototype.initialize = function() {};

  BaseView.prototype.getRenderData = function() {
    var _ref;
    return {
      model: (_ref = this.model) != null ? _ref.toJSON() : void 0
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

;require.register("lib/folder_helpers", function(exports, require, module) {
module.exports = {
  removeTralingSlash: function(path) {
    if (path.slice(-1) === '/') {
      return path.slice(0, -1);
    }
    return path;
  },
  dirName: function(path) {
    return path.split('/').slice(0, -1).join('/');
  },
  nestedDirs: function(fileList) {
    var dir, dirs, file, levels, nestLevel, parent, path, relPath, _i, _len;
    levels = {};
    for (_i = 0, _len = fileList.length; _i < _len; _i++) {
      file = fileList[_i];
      relPath = file.relativePath || file.mozRelativePath || file.webkitRelativePath;
      parent = relPath.slice(0, relPath.lastIndexOf(file.name));
      nestLevel = parent.split('/').length - 1;
      levels[parent] = nestLevel;
    }
    dirs = (function() {
      var _j, _len1, _ref, _results;
      _ref = Object.keys(levels);
      _results = [];
      for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
        path = _ref[_j];
        _results.push({
          path: path,
          nestLevel: levels[path]
        });
      }
      return _results;
    })();
    dirs.sort(function(a, b) {
      return a.nestLevel - b.nestLevel;
    });
    return (function() {
      var _j, _len1, _results;
      _results = [];
      for (_j = 0, _len1 = dirs.length; _j < _len1; _j++) {
        dir = dirs[_j];
        _results.push(dir.path);
      }
      return _results;
    })();
  }
};

});

;require.register("lib/view_collection", function(exports, require, module) {
var BaseView, ViewCollection,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('lib/base_view');

module.exports = ViewCollection = (function(_super) {
  __extends(ViewCollection, _super);

  function ViewCollection() {
    this.removeItem = __bind(this.removeItem, this);
    this.addItem = __bind(this.addItem, this);
    return ViewCollection.__super__.constructor.apply(this, arguments);
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
    var id, view, _ref;
    _ref = this.views;
    for (id in _ref) {
      view = _ref[id];
      view.$el.detach();
    }
    return ViewCollection.__super__.render.apply(this, arguments);
  };

  ViewCollection.prototype.afterRender = function() {
    var id, view, _ref;
    this.$collectionEl = $(this.collectionEl);
    _ref = this.views;
    for (id in _ref) {
      view = _ref[id];
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
    var id, view, _ref;
    _ref = this.views;
    for (id in _ref) {
      view = _ref[id];
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

;require.register("locales/en", function(exports, require, module) {
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
  "modal error empty name": "Name can't be empty",
  "modal error no data": "No name and no folder to upload",
  "tag": "tag",
  "file edit save": "Save",
  "file edit cancel": "cancel",
  "tooltip delete": "Delete",
  "tooltip edit": "Rename",
  "tooltip download": "Download",
  "tooltip share": "Share",
  "upload caption": "Upload a new file",
  "upload msg": "Choose the file to upload:",
  "upload close": "Close",
  "upload send": "Add",
  "upload button": "Upload a file here",
  "new folder caption": "Add a new folder",
  "new folder msg": "Create a folder named:",
  "new folder close": "Close",
  "new folder send": "OK",
  "new folder button": "Create a new folder",
  "upload folder msg": "Upload a folder",
  "folder": "Folder",
  "image": "Image",
  "document": "Document",
  "music": "Music",
  "video": "Video",
  "yes": "Yes",
  "no": "No",
  "name": "Name",
  "type": "Type",
  "size": "Size",
  "date": "Last update",
  "download": "Download",
  "MB": "MB",
  "KB": "KB",
  "B": "B",
  "enable notifications": "Enable notifications",
  "disable notifications": "Disable notifications",
  "notifications enabled": "Notifications enabled",
  "notifications disabled": "Notifications disabled",
  "open folder": "Open the folder",
  "download file": "View the file",
  "also have access": "These people also have access, because they have access to a parent folder",
  "cancel": "Cancel",
  "copy paste link": "To give access to your contact send him/her the link below:",
  "details": "Details",
  "inherited from": "inherited from",
  "modal question folder shareable": "Select share mode for this folder",
  "modal shared folder custom msg": "Enter email and press enter",
  "modal shared folder link msg": "Send this link to let people access this folder",
  "modal send mails": "Send a notification",
  "modal question file shareable": "Select share mode for this file",
  "modal shared file custom msg": "Enter email and press enter",
  "modal shared file link msg": "Send this link to let people access this file",
  "only you can see": "Only you and the people listed below can access this resource",
  "public": "Public",
  "private": "Private",
  "save": "Save",
  "see link": "See link",
  "send mails question": "Send a notification email to:",
  "sharing": "Sharing",
  "revoke": "Revoke",
  "forced public": "This is public because one of the parent folder is public:",
  "perm": "can ",
  "perm r file": "download this file",
  "perm r folder": "browse this folder",
  "perm rw folder": "browse and upload files",
  "change notif": "Check this box to be notified when a contact\nadd a file to this folder."
};

});

;require.register("locales/fr", function(exports, require, module) {
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
  "tag": "étiquette",
  "tooltip delete": "Supprimer",
  "tooltip edit": "Renommer",
  "tooltip download": "Télécharger",
  "tooltip share": "Partager",
  "file edit save": "Sauvegarder",
  "file edit cancel": "Annuler",
  "upload caption": "Téléverser un fichier",
  "upload msg": "Choisir un fichier à téléverser :",
  "upload close": "Annuler",
  "upload send": "Ajouter",
  "upload button": "Téléverser un fichier",
  "new folder caption": "Créer un nouveau dossier",
  "new folder msg": "Entrer le nom du dossier :",
  "new folder close": "Annuler",
  "new folder send": "Créer",
  "new folder button": "Créer un nouveau dossier",
  "upload folder msg": "Téléverser un dossier",
  "folder": "Dossier",
  "image": "Image",
  "document": "Document",
  "music": "Musique",
  "video": "Vidéo",
  "yes": "Oui",
  "no": "Non",
  "name": "Nom",
  "type": "Type",
  "size": "Taille",
  "date": "Dernière modification",
  "download": "Télécharger",
  "MB": "Mo",
  "KB": "Ko",
  "B": "o",
  "enable notifications": "Activer les notifications",
  "disable notifications": "Désactiver les notifications",
  "notifications enabled": "Notifications activées",
  "notifications disabled": "Notifications désactivées",
  "open folder": "Ouvrir le dossier",
  "download file": "Consulter le fichier",
  "also have access": "Ces personnes ont égalment accès, car ils ont accès à un dossier parent",
  "cancel": "Annuler",
  "copy paste link": "Pour donner accès à votre contact envoyez lui ce lien : ",
  "details": "Details",
  "inherited from": "hérité de",
  "modal question folder shareable": "Choisissez le mode de partage pour ce dossier",
  "modal shared folder custom msg": "Entrez un email et appuyez sur enter",
  "modal shared folder link msg": "Envoyez ce lien pour qu'ils puissent accéder à ce dossier",
  "modal question file shareable": "Choisissez le mode de partage pour ce fichier",
  "modal shared file custom msg": "Entrez un email et appuyez sur enter",
  "modal shared file link msg": "Envoyez ce lien pour qu'ils puissent accéder à ce dossier",
  "only you can see": "Seul vous et les personnes ci-dessous peuvent accéder à cette ressource.",
  "public": "Publique",
  "private": "Privé",
  "save": "Sauvegarder",
  "see link": "Voir le lien",
  "sharing": "Partage",
  "revoke": "Révoquer la permission",
  "send mails question": "Envoyer un email de notification à : ",
  "modal send mails": "Envoyer une notification",
  "perm": "peut ",
  "perm r file": "consulter ce fichier",
  "perm r folder": "parcourir ce dossier",
  "perm rw folder": "parcourir ce dossier et ajouter des fichiers",
  "change notif": "Cocher cette case pour recevoir une notification cozy quand un contact\najoute un fichier à ce dossier."
};

});

;require.register("locales/ro", function(exports, require, module) {
module.exports = {
  "modal error": "Eroare",
  "modal ok": "OK",
  "modal error get files": "A apărut o eroare în transferul de fișiere de la server",
  "modal error get folders": "A apărut o eroare în transferul de directoare de la server",
  "modal error empty name": "Numele nu poate fi vid",
  "modal error file invalid": "Fișierul nu pare a fi valid",
  "breadcrumbs search title": "Căutare",
  "modal error file exists": "Ne pare rău, există deja un document cu acest nume",
  "modal error file upload": "Fișierul nu a putut fi trimis server-ului",
  "modal error folder create": "Directorul nu a putut fi creat",
  "modal error folder exists": "Ne pare rău, există deja un director cu acest nume",
  "modal are you sure": "Sunteți sigur(ă)?",
  "modal delete msg": "Ștergerea nu poate fi anulată",
  "modal delete ok": "Ștergere",
  "modal cancel": "Anulare",
  "modal delete error": "Anulare",
  "modal error in use": "Nume deja folosit",
  "modal error rename": "Numele nu a putut fi schimbat",
  "modal error empty name": "Numele nu poate fi vid",
  "modal error no data": "Nu există date de încărcat",
  "tag": "etichetă",
  "file edit save": "Salvare",
  "file edit cancel": "Anulare",
  "tooltip delete": "Ștergere",
  "tooltip edit": "Redenumire",
  "tooltip download": "Descărcare",
  "tooltip share": "Partajare",
  "upload caption": "Încărcare fișier",
  "upload msg": "Alegeți fișierul de încărcat:",
  "upload close": "Anulare",
  "upload send": "Încărcare",
  "upload button": "Încărcați un fișier aici",
  "new folder caption": "Adăugați un nou director",
  "new folder msg": "Creați un director cu numele:",
  "new folder close": "Anulare",
  "new folder send": "OK",
  "new folder button": "Creare director",
  "upload folder msg": "Încărcați un director",
  "folder": "Director",
  "image": "Imagine",
  "document": "Document",
  "music": "Muzică",
  "video": "Video",
  "yes": "Da",
  "no": "Nu",
  "name": "Nume",
  "type": "Tip",
  "size": "Dimensiune",
  "date": "Ultima modificare",
  "download": "Descărcare",
  "MB": "Mo",
  "KB": "Ko",
  "B": "o",
  "enable notifications": "Enable notifications",
  "disable notifications": "Disable notifications",
  "open folder": "Browse the folder",
  "download file": "View the file",
  "also have access": "Aceste persoane au acces, deoarece au acces la un director părinte",
  "cancel": "Anulare",
  "copy paste link": "Pentru a oferi acces la dvs. de contact trimite el/ea pe link-ul de mai jos: ",
  "details": "Detalii",
  "inherited from": "moștenit de la",
  "modal question folder shareable": "Alegeți modul de partajare pentru acest director",
  "modal shared folder custom msg": "Introduceți adresa de e-mail și apăsați Enter",
  "modal shared folder link msg": "Trimiteți această adresă persoanelor pentru a putea accesa directorul",
  "modal send mails": "Trimiteți o notificare",
  "modal question file shareable": "Alegeți modul de partajare pentru acest document",
  "modal shared file custom msg": "Introduceți adresa de e-mail și apăsați Enter",
  "modal shared file link msg": "Trimiteți această adresă persoanelor pentru a putea accesa directorul",
  "only you can see": "Numai Dvs. și persoanele de mai jos au acces",
  "public": "Public",
  "private": "Privat",
  "save": "Salvare",
  "see link": "Vedeți adresă",
  "send mails question": "Trimiteți e-mail de notificare la: ",
  "sharing": "Partajare",
  "revoke": "Revocare permisiune",
  "forced public": "Acesta este public deoarece un director părinte este public: ",
  "perm": "poate ",
  "perm r file": "descărca acest fișier",
  "perm r folder": "parcurge acest dosar ",
  "perm rw folder": "parcurge acest dosar și încărca fișiere",
  "change notif": "Bifați această casetă pentru a fi notificat atunci când o persoană de contact\nadăuga un fișier în acest dosar."
};

});

;require.register("models/file", function(exports, require, module) {
var File, client,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

client = require("../helpers/client");

module.exports = File = (function(_super) {
  __extends(File, _super);

  function File() {
    return File.__super__.constructor.apply(this, arguments);
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
    var error, success, _ref;
    _ref = callbacks || {}, success = _ref.success, error = _ref.error;
    if (presuccess == null) {
      presuccess = (function(_this) {
        return function(data) {
          return _this.set(data.app);
        };
      })(this);
    }
    this.trigger('request', this, null, callbacks);
    callbacks.success = (function(_this) {
      return function(data) {
        if (presuccess) {
          presuccess(data);
        }
        _this.trigger('sync', _this, null, callbacks);
        if (success) {
          return success(data);
        }
      };
    })(this);
    return callbacks.error = (function(_this) {
      return function(jqXHR) {
        if (preerror) {
          preerror(jqXHR);
        }
        _this.trigger('error', _this, jqXHR, {});
        if (error) {
          return error(jqXHR);
        }
      };
    })(this);
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

  File.prototype.getPublicURL = function(key) {
    return "" + window.location.origin + "/public/files/" + (this.urlRoot()) + this.id;
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

;require.register("router", function(exports, require, module) {
var File, FolderView, Router, app,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

app = require('application');

FolderView = require('./views/folder');

File = require('./models/file');

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
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
    var folder;
    folder = new File({
      id: id,
      type: "folder"
    });
    return folder.fetch({
      success: (function(_this) {
        return function(data) {
          folder.set(data);
          return app.folderView.changeActiveFolder(folder);
        };
      })(this)
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

;require.register("views/breadcrumbs", function(exports, require, module) {
var BaseView, BreadcrumbsView, ModalShareView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

ModalShareView = require('./modal_share');

module.exports = BreadcrumbsView = (function(_super) {
  __extends(BreadcrumbsView, _super);

  BreadcrumbsView.prototype.itemview = require('./templates/breadcrumbs_element');

  BreadcrumbsView.prototype.tagName = "ul";

  BreadcrumbsView.prototype.events = {
    'click .share-state': 'onShareClicked'
  };

  function BreadcrumbsView(collection) {
    this.collection = collection;
    BreadcrumbsView.__super__.constructor.call(this);
  }

  BreadcrumbsView.prototype.initialize = function() {
    this.listenTo(this.collection, "reset", this.render);
    this.listenTo(this.collection, "add", this.render);
    return this.listenTo(this.collection, "remove", this.render);
  };

  BreadcrumbsView.prototype.onShareClicked = function() {
    var lastModel;
    if (!(this.collection.length > 1)) {
      return;
    }
    lastModel = this.collection.at(this.collection.length - 1);
    this.listenTo(lastModel, 'change', this.render);
    return new ModalShareView({
      model: lastModel
    });
  };

  BreadcrumbsView.prototype.render = function() {
    var clearance, folder, shareState, _i, _len, _ref;
    this.$el.html("");
    _ref = this.collection.models;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      folder = _ref[_i];
      this.$el.append(this.itemview({
        model: folder
      }));
    }
    if (this.collection.length > 1) {
      shareState = $('<li class="share-state"></li>');
      clearance = folder.get('clearance');
      if (clearance === 'public') {
        shareState.append($('<span class="fa fa-globe"></span>'));
      } else if (clearance && clearance.length > 0) {
        shareState.append($("<span class='fa fa-users'>" + ("" + clearance.length + "</span>")));
      } else {
        shareState.append($('<span class="fa fa-lock"></span>'));
      }
      this.$el.append(shareState);
    }
    return this;
  };

  return BreadcrumbsView;

})(BaseView);

});

;require.register("views/file", function(exports, require, module) {
var BaseView, FileView, ModalShareView, ModalView, TagsView, client,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

ModalView = require("./modal");

ModalShareView = require("./modal_share");

TagsView = require("./tags");

client = require("../helpers/client");

module.exports = FileView = (function(_super) {
  __extends(FileView, _super);

  function FileView() {
    this.onKeyPress = __bind(this.onKeyPress, this);
    return FileView.__super__.constructor.apply(this, arguments);
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
    return new ModalView(t("modal are you sure"), t("modal delete msg"), t("modal delete ok"), t("modal cancel"), (function(_this) {
      return function(confirm) {
        if (confirm) {
          return _this.model.destroy({
            error: function() {
              return new ModalView(t("modal error"), t("modal delete error"), t("modal ok"));
            }
          });
        }
      };
    })(this));
  };

  FileView.prototype.onEditClicked = function() {
    var model, width;
    width = this.$(".caption").width() + 10;
    model = this.model.toJSON();
    if (model["class"] == null) {
      model["class"] = 'folder';
    }
    this.$el.html(this.templateEdit({
      model: model
    }));
    this.tags = new TagsView({
      el: this.$('.tags'),
      model: this.model
    });
    this.tags.render();
    this.$(".file-edit-name").width(width);
    return this.$(".file-edit-name").focus();
  };

  FileView.prototype.onShare = function() {
    return new ModalShareView({
      model: this.model
    });
  };

  FileView.prototype.onSaveClicked = function() {
    var name;
    name = this.$('.file-edit-name').val();
    if (name && name !== "") {
      return this.model.save({
        name: name
      }, {
        wait: true,
        success: (function(_this) {
          return function(data) {
            return _this.render();
          };
        })(this),
        error: (function(_this) {
          return function(model, err) {
            console.log(err);
            if (err.status === 400) {
              return new ModalView(t("modal error"), t("modal error in use"), t("modal ok"));
            } else {
              return new ModalView(t("modal error"), t("modal error rename"), t("modal ok"));
            }
          };
        })(this)
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

  FileView.prototype.afterRender = function() {
    this.tags = new TagsView({
      el: this.$('.tags'),
      model: this.model
    });
    return this.tags.render();
  };

  return FileView;

})(BaseView);

});

;require.register("views/files", function(exports, require, module) {
var File, FileCollection, FileView, FilesView, ModalView, ProgressbarView, SocketListener, ViewCollection,
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
    return FilesView.__super__.constructor.apply(this, arguments);
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

  FilesView.prototype.addFile = function(attach, dirUpload) {
    var dialogEl, file, fileAttributes, found, progress;
    found = this.collection.findWhere({
      name: attach.name
    });
    if (!found) {
      fileAttributes = {
        'name': attach.name,
        'path': attach.path || this.model.repository(),
        'type': "file",
        'lastModification': attach.lastModifiedDate
      };
      file = new File(fileAttributes);
      file.file = attach;
      progress = new ProgressbarView(file);
      if (dirUpload) {
        dialogEl = "dialog-new-folder";
      } else {
        dialogEl = "dialog-upload-file";
      }
      $("#" + dialogEl + " .modal-body").append("<div class=\"progress-name\">" + attach.name + "</div>");
      $("#" + dialogEl + " .modal-body").append(progress.render().el);
      return this.upload(file, dirUpload);
    } else {
      return new ModalView(t("modal error"), "" + (t('modal error file exists')) + ": " + attach.name, t("modal ok"));
    }
  };

  FilesView.prototype.upload = function(file, noDisplay) {
    var formdata;
    formdata = new FormData();
    formdata.append('cid', file.cid);
    formdata.append('name', file.get('name'));
    formdata.append('path', file.get('path'));
    formdata.append('file', file.file);
    formdata.append('lastModification', file.get('lastModification'));
    return file.save(null, {
      contentType: false,
      data: formdata,
      success: (function(_this) {
        return function(data) {
          if (!noDisplay) {
            return _this.collection.add(file, {
              merge: true
            });
          }
        };
      })(this),
      error: (function(_this) {
        return function() {
          return new ModalView(t("modal error"), t("modal error file upload"), t("modal ok"));
        };
      })(this)
    });
  };

  FilesView.prototype.addFolder = function(folder, noDisplay) {
    var found;
    found = this.collection.findWhere({
      name: folder.get("name"),
      path: folder.get("path")
    });
    if (!found) {
      return folder.save(null, {
        success: (function(_this) {
          return function(data) {
            if (!noDisplay) {
              return _this.collection.add(folder);
            }
          };
        })(this),
        error: (function(_this) {
          return function(error) {
            return new ModalView(t("modal error"), t("modal error folder create"), t("modal ok"));
          };
        })(this)
      });
    } else {
      return new ModalView(t("modal error"), t("modal error folder exists"), t("modal ok"));
    }
  };

  return FilesView;

})(ViewCollection);

});

;require.register("views/folder", function(exports, require, module) {
var BaseView, BreadcrumbsView, File, FileCollection, FilesView, FolderView, Helpers, ModalView, ProgressbarView,
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

Helpers = require('../lib/folder_helpers');

module.exports = FolderView = (function(_super) {
  __extends(FolderView, _super);

  function FolderView() {
    this.onSearchKeyPress = __bind(this.onSearchKeyPress, this);
    this.onDragAndDrop = __bind(this.onDragAndDrop, this);
    this.onAddFile = __bind(this.onAddFile, this);
    this.onAddFolder = __bind(this.onAddFolder, this);
    return FolderView.__super__.constructor.apply(this, arguments);
  }

  FolderView.prototype.template = require('./templates/folder');

  FolderView.prototype.events = function() {
    return {
      'click a#button-new-folder': 'prepareNewFolder',
      'click a#button-upload-new-file': 'onUploadNewFileClicked',
      'click #new-folder-send': 'onAddFolder',
      'click #cancel-new-folder': 'onCancelFolder',
      'click #upload-file-send': 'onAddFile',
      'click #cancel-new-file': 'onCancelFile',
      'click #up-name': 'onChangeOrder',
      'click #down-name': 'onChangeOrder',
      'click #up-class': 'onChangeOrder',
      'click #down-class': 'onChangeOrder',
      'click #up-size': 'onChangeOrder',
      'click #down-size': 'onChangeOrder',
      'click #up-lastModification': 'onChangeOrder',
      'click #down-lastModification': 'onChangeOrder',
      'keyup input#search-box': 'onSearchKeyPress',
      'keyup input#inputName': 'onAddFolderEnter'
    };
  };

  FolderView.prototype.initialize = function(options) {
    this.model = options.model;
    this.breadcrumbs = options.breadcrumbs;
    this.breadcrumbs.setRoot(this.model);
    return this.setDragNDrop();
  };

  FolderView.prototype.setDragNDrop = function() {
    var prevent;
    prevent = function(e) {
      e.preventDefault();
      return e.stopPropagation();
    };
    this.$el.on("dragover", prevent);
    this.$el.on("dragenter", prevent);
    return this.$el.on("drop", (function(_this) {
      return function(e) {
        return _this.onDragAndDrop(e);
      };
    })(this));
  };

  FolderView.prototype.getRenderData = function() {
    return {
      model: this.model
    };
  };

  FolderView.prototype.afterRender = function() {
    this.breadcrumbsView = new BreadcrumbsView(this.breadcrumbs);
    this.$("#crumbs").append(this.breadcrumbsView.render().$el);
    return this.displayChevron('up', 'name');
  };

  FolderView.prototype.displayChevron = function(order, type) {
    this.$('#up-name').show();
    this.$('#up-name').addClass('unactive');
    this.$('#down-name').hide();
    this.$('#up-size').show();
    this.$('#up-size').addClass('unactive');
    this.$('#down-size').hide();
    this.$('#up-class').show();
    this.$('#up-class').addClass('unactive');
    this.$('#down-class').hide();
    this.$('#up-lastModification').show();
    this.$('#up-lastModification').addClass('unactive');
    this.$('#down-lastModification').hide();
    if (order === "down") {
      this.$("#up-" + type).show();
      this.$("#down-" + type).hide();
      return this.$("#up-" + type).removeClass('unactive');
    } else {
      this.$("#up-" + type).hide();
      this.$("#down-" + type).show();
      return this.$("#down-" + type).removeClass('unactive');
    }
  };

  FolderView.prototype.changeActiveFolder = function(folder) {
    var _ref;
    this.model = folder;
    this.breadcrumbs.push(folder);
    if (folder.id === "root") {
      this.$("#crumbs").css({
        opacity: 0.5
      });
    } else {
      this.$("#crumbs").css({
        opacity: 1
      });
    }
    if (folder.get("type") === "folder") {
      this.$("#upload-buttons").show();
    } else {
      this.$("#upload-buttons").hide();
    }
    if ((_ref = this.filesList) != null) {
      _ref.$el.html(null);
    }
    this.$("#loading-indicator").spin('small');
    return this.model.findFiles({
      success: (function(_this) {
        return function(files) {
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
              _this.filesList.render();
              return _this.$("#loading-indicator").spin();
            },
            error: function(error) {
              console.log(error);
              new ModalView(t("modal error"), t("modal error get folders"), t("modal ok"));
              return _this.$("#loading-indicator").spin();
            }
          });
        };
      })(this),
      error: (function(_this) {
        return function(error) {
          console.log(error);
          return new ModalView(t("modal error"), t("modal error get files"), t("modal ok"));
        };
      })(this)
    });
  };

  FolderView.prototype.onUploadNewFileClicked = function() {
    return $("#dialog-upload-file .progress-name").remove();
  };

  FolderView.prototype.prepareNewFolder = function() {
    var supportsDirectoryUpload, uploadDirectoryInput;
    uploadDirectoryInput = this.$("#folder-uploader")[0];
    supportsDirectoryUpload = uploadDirectoryInput.directory || uploadDirectoryInput.mozdirectory || uploadDirectoryInput.webkitdirectory || uploadDirectoryInput.msdirectory;
    $("#dialog-new-folder .progress-name").remove();
    if (supportsDirectoryUpload) {
      this.$("#folder-upload-form").removeClass('hide');
    }
    return setTimeout((function(_this) {
      return function() {
        return _this.$("#inputName").focus();
      };
    })(this), 500);
  };

  FolderView.prototype.onCancelFolder = function() {
    return this.$("#inputName").val("");
  };

  FolderView.prototype.onAddFolderEnter = function(e) {
    if (e.keyCode === 13) {
      e.preventDefault();
      e.stopPropagation();
      return this.onAddFolder();
    }
  };

  FolderView.prototype.onAddFolder = function() {
    var dir, dirsToCreate, file, files, folder, nFolder, parts, path, prefix, relPath, response, _i, _j, _len, _len1;
    prefix = this.model.repository();
    folder = new File({
      name: this.$('#inputName').val(),
      path: prefix,
      type: "folder"
    });
    this.$("#inputName").val("");
    files = this.$('#folder-uploader')[0].files;
    if (!files.length && folder.validate()) {
      new ModalView(t("modal error"), t("modal error no data"), t("modal ok"));
      return;
    }
    if (!folder.validate()) {
      this.filesList.addFolder(folder);
    }
    if (files.length) {
      dirsToCreate = Helpers.nestedDirs(files);
      for (_i = 0, _len = dirsToCreate.length; _i < _len; _i++) {
        dir = dirsToCreate[_i];
        dir = Helpers.removeTralingSlash(dir);
        parts = dir.split('/');
        path = prefix + "/" + parts.slice(0, -1).join('/');
        path = Helpers.removeTralingSlash(path);
        nFolder = new File({
          name: parts.slice(-1)[0],
          path: path,
          type: "folder"
        });
        response = this.filesList.addFolder(nFolder, true);
        if (response instanceof ModalView) {
          return;
        }
      }
      files = (function() {
        var _j, _len1, _results;
        _results = [];
        for (_j = 0, _len1 = files.length; _j < _len1; _j++) {
          file = files[_j];
          if (file.name !== "." && file.name !== "..") {
            _results.push(file);
          }
        }
        return _results;
      })();
      for (_j = 0, _len1 = files.length; _j < _len1; _j++) {
        file = files[_j];
        relPath = file.relativePath || file.mozRelativePath || file.webkitRelativePath || file.msRelativePath;
        file.path = prefix + "/" + Helpers.dirName(relPath);
        response = this.filesList.addFile(file, true);
        if (response instanceof ModalView) {
          return;
        }
      }
    }
  };

  FolderView.prototype.onAddFile = function() {
    var attach, _i, _len, _ref;
    _ref = this.$('#uploader')[0].files;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      attach = _ref[_i];
      this.filesList.addFile(attach);
    }
    return this.$('#uploader').val("");
  };

  FolderView.prototype.onCancelFile = function() {
    return this.$("#uploader").val("");
  };

  FolderView.prototype.onDragAndDrop = function(e) {
    var atLeastOne, attach, _i, _len, _ref;
    e.preventDefault();
    e.stopPropagation();
    atLeastOne = false;
    _ref = e.dataTransfer.files;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      attach = _ref[_i];
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
    $('#dialog-upload-file').modal('hide');
    return $('#dialog-new-folder').modal('hide');
  };


  /*
      Search
   */

  FolderView.prototype.onSearchKeyPress = function(e) {
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

  FolderView.prototype.onChangeOrder = function(event) {
    var infos, type, way;
    infos = event.target.id.split('-');
    way = infos[0];
    type = infos[1];
    this.displayChevron(way, type);
    this.filesCollection.type = type;
    if (this.filesCollection.order === "incr") {
      this.filesCollection.order = "decr";
      return this.filesCollection.sort();
    } else {
      this.filesCollection.order = "incr";
      return this.filesCollection.sort();
    }
  };

  return FolderView;

})(BaseView);

});

;require.register("views/modal", function(exports, require, module) {
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
    this.$('#modal-dialog').modal('hide');
    if (this.cb) {
      this.cb(true);
    }
    return setTimeout((function(_this) {
      return function() {
        return _this.destroy();
      };
    })(this), 1000);
  };

  ModalView.prototype.onNo = function() {
    if (this.cb) {
      this.cb(false);
    }
    this.$('#modal-dialog').modal('hide');
    return setTimeout((function(_this) {
      return function() {
        return _this.destroy();
      };
    })(this), 1000);
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

module.exports.error = function(code, cb) {
  return new ModalView(t("modal error"), t(code), t("modal ok"), false, cb);
};

});

;require.register("views/modal_share", function(exports, require, module) {
var BaseView, CozyClearanceModal, Modal, ModalShareView, client,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

BaseView = require('../lib/base_view');

Modal = require("./modal");

client = require("../helpers/client");

CozyClearanceModal = require("cozy-clearance/modal_share_view");

module.exports = ModalShareView = (function(_super) {
  __extends(ModalShareView, _super);

  function ModalShareView() {
    this.typeaheadFilter = __bind(this.typeaheadFilter, this);
    return ModalShareView.__super__.constructor.apply(this, arguments);
  }

  ModalShareView.prototype.events = function() {
    return _.extend(ModalShareView.__super__.events.apply(this, arguments), {
      'click #inherited-share-summary a': (function(_this) {
        return function() {
          _this.$('#inherited-share-list').show();
          return _this.$('#inherited-share-summary').hide();
        };
      })(this)
    });
  };

  ModalShareView.prototype.initialize = function(options) {
    this.type = this.model.get('type');
    ModalShareView.__super__.initialize.apply(this, arguments);
    this.summaryemails = [];
    return client.get("clearance/" + this.model.id, {
      error: (function(_this) {
        return function() {
          return Modal.error('server error occured', function() {
            return _this.$el.modal('hide');
          });
        };
      })(this),
      success: (function(_this) {
        return function(data) {
          var last;
          _this.inherited = data.inherited;
          last = _.last(_this.inherited);
          if ((last != null ? last.clearance : void 0) === 'public') {
            _this.forcedPublic = last.name;
          }
          return _this.refresh();
        };
      })(this)
    });
  };

  ModalShareView.prototype.permissions = function() {
    if (this.type === 'folder') {
      return {
        'r': 'perm r folder',
        'rw': 'perm rw folder'
      };
    } else {
      return {
        'r': 'perm r file'
      };
    }
  };

  ModalShareView.prototype.typeaheadFilter = function(item) {
    var email;
    email = item.toString().split(';')[0];
    return ModalShareView.__super__.typeaheadFilter.apply(this, arguments) && __indexOf.call(this.summaryemails, email) < 0;
  };

  ModalShareView.prototype.getRenderData = function() {
    var out;
    out = ModalShareView.__super__.getRenderData.apply(this, arguments);
    if (this.forcedPublic) {
      out.clearance = 'public';
    }
    return out;
  };

  ModalShareView.prototype.makePublic = function() {
    if (this.forcedPublic) {
      return;
    }
    return ModalShareView.__super__.makePublic.apply(this, arguments);
  };

  ModalShareView.prototype.afterRender = function() {
    var checkbox, folder, guestCanWrite, html, item, label, list, listitems, rule, summary, text, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
    ModalShareView.__super__.afterRender.apply(this, arguments);
    if (this.forcedPublic) {
      text = t('forced public') + this.forcedPublic;
      this.$('#share-public').addClass('toggled');
      this.$('#share-private').hide().after($('<p>').text(text));
    } else {
      listitems = [];
      summary = [];
      _ref = this.inherited;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        folder = _ref[_i];
        if (!(folder.clearance.length !== 0)) {
          continue;
        }
        text = t('inherited from') + folder.name;
        listitems.push($('<li>').addClass('header').text(text));
        _ref1 = folder.clearance;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          rule = _ref1[_j];
          summary.push(rule.email);
          listitems.push($('<li>').text(rule.email));
        }
      }
      if (summary.length !== 0) {
        this.summaryemails = summary;
        text = t('also have access') + ' : ' + summary.join(', ') + '. ';
        summary = $('<div id="inherited-share-summary">').text(text);
        summary.append($('<a>').text(t('details')));
        list = $('<ul id="inherited-share-list">').hide();
        for (_k = 0, _len2 = listitems.length; _k < _len2; _k++) {
          item = listitems[_k];
          list.append(item);
        }
        this.$('#share-list').after(summary, list);
      }
    }
    guestCanWrite = _.findWhere(this.model.get('clearance'), {
      perm: 'rw'
    });
    if (guestCanWrite) {
      checkbox = $('<input id="notifs" type="checkbox">');
      checkbox.prop('checked', this.model.get('changeNotification'));
      text = t('change notif');
      html = '<label class="notifs-label" for="notifs">';
      label = $(html).append(checkbox, text);
      return this.$('#share-list').after(label);
    }
  };

  ModalShareView.prototype.saveData = function() {
    var changeNotification;
    changeNotification = this.$('#notifs').prop('checked') || false;
    return _.extend(ModalShareView.__super__.saveData.apply(this, arguments), {
      changeNotification: changeNotification
    });
  };

  return ModalShareView;

})(CozyClearanceModal);

});

;require.register("views/progressbar", function(exports, require, module) {
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

;require.register("views/public_folder", function(exports, require, module) {
var File, FileCollection, FilesView, FolderView, PublicFilesView, PublicFolderView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

window.CozySocketListener = {
  fake: ''
};

FolderView = require('./folder');

File = require('../models/file');

FilesView = require('./files');

FileCollection = require('../collections/files');

PublicFilesView = (function(_super) {
  __extends(PublicFilesView, _super);

  function PublicFilesView() {
    return PublicFilesView.__super__.constructor.apply(this, arguments);
  }

  PublicFilesView.prototype.initialize = function(collection, model) {
    this.collection = collection;
    this.model = model;
    return FilesView.__super__.initialize.apply(this, arguments);
  };

  PublicFilesView.prototype.addItem = function() {
    return window.location.reload();
  };

  return PublicFilesView;

})(FilesView);

module.exports = PublicFolderView = (function(_super) {
  __extends(PublicFolderView, _super);

  function PublicFolderView() {
    return PublicFolderView.__super__.constructor.apply(this, arguments);
  }

  PublicFolderView.prototype.el = document.getElementsByTagName('body')[0];

  PublicFolderView.prototype.templates = function() {
    return '';
  };

  PublicFolderView.prototype.initialize = function(options) {
    var old;
    this.model = new File(_.extend(options.folder, {
      type: 'folder'
    }));
    old = File.prototype.urlRoot;
    File.prototype.urlRoot = function() {
      return '../' + old.apply(this, arguments) + window.location.search;
    };
    this.filesCollection = new FileCollection([]);
    return this.filesList = new PublicFilesView(this.filesCollection, this.model);
  };

  PublicFolderView.prototype.onCancelFolder = function() {
    PublicFolderView.__super__.onCancelFolder.apply(this, arguments);
    if (this.$('.progress-name').length) {
      return window.location.reload();
    }
  };

  return PublicFolderView;

})(FolderView);

});

;require.register("views/tags", function(exports, require, module) {
var BaseView, TagsView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

module.exports = TagsView = (function(_super) {
  __extends(TagsView, _super);

  function TagsView() {
    this.refresh = __bind(this.refresh, this);
    this.tagRemoved = __bind(this.tagRemoved, this);
    this.tagClicked = __bind(this.tagClicked, this);
    this.tagAdded = __bind(this.tagAdded, this);
    return TagsView.__super__.constructor.apply(this, arguments);
  }

  TagsView.prototype.initialize = function() {
    return TagsView.__super__.initialize.apply(this, arguments);
  };

  TagsView.prototype.afterRender = function() {
    this.$el.tagit({
      availableTags: [],
      placeholderText: t('tag'),
      afterTagAdded: this.tagAdded,
      afterTagRemoved: this.tagRemoved,
      onTagClicked: this.tagClicked
    });
    this.duringRefresh = false;
    $('.ui-widget-content .ui-autocomplete-input').keypress(function(event) {
      var keyCode;
      keyCode = event.keyCode || event.which;
      if (keyCode === 9) {
        return $('.zone .type').first().select();
      }
    });
    return this;
  };

  TagsView.prototype.tagAdded = function(event, ui) {
    if (!(this.duringRefresh || ui.duringInitialization)) {
      this.model.set('tags', this.$el.tagit('assignedTags'));
      return this.model.save();
    }
  };

  TagsView.prototype.tagClicked = function(event, ui) {
    $("#search-box").val("tag:" + ui.tagLabel);
    $("#search-box").trigger('keyup');
    return $(".dropdown-menu").hide();
  };

  TagsView.prototype.tagRemoved = function(event, ui) {
    if (!(this.duringRefresh || ui.duringInitialization)) {
      this.model.set('tags', this.$el.tagit('assignedTags'));
      return this.model.save();
    }
  };

  TagsView.prototype.refresh = function() {
    var tag, _i, _len, _ref;
    this.duringRefresh = true;
    this.$el.tagit('removeAll');
    _ref = this.model.get('tags');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tag = _ref[_i];
      this.$el.tagit('createTag', tag);
    }
    return this.duringRefresh = false;
  };

  return TagsView;

})(BaseView);

});

;require.register("views/templates/breadcrumbs_element", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
if ( model.id == "root")
{
buf.push('<li><a href="#"><span class="glyphicon glyphicon-home"> </span></a></li>');
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

;require.register("views/templates/file", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
if ( model.type && model.type == "folder")
{
buf.push('<td><div class="caption-wrapper"><a');
buf.push(attrs({ 'href':("#folders/" + (model.id) + ""), 'title':("" + (t('open folder')) + ""), "class": ('caption') + ' ' + ('btn') + ' ' + ('btn-link') }, {"href":true,"title":true}));
buf.push('><i class="fa fa-folder"></i>' + escape((interp = model.name) == null ? '' : interp) + '</a></div><div class="operations"><a');
buf.push(attrs({ 'title':("" + (t('tooltip share')) + ""), "class": ('file-share') }, {"title":true}));
buf.push('>');
if ( model.clearance == 'public')
{
buf.push('<span class="fa fa-globe"></span>');
}
else if ( model.clearance && model.clearance.length > 0)
{
buf.push('<span class="fa fa-users">' + escape((interp = model.clearance.length) == null ? '' : interp) + '</span>');
}
else
{
buf.push('<span class="fa fa-lock"></span>');
}
buf.push('</a><a');
buf.push(attrs({ 'title':("" + (t('tooltip edit')) + ""), "class": ('file-edit') }, {"title":true}));
buf.push('><span class="glyphicon glyphicon-edit"></span></a><a');
buf.push(attrs({ 'title':("" + (t('tooltip delete')) + ""), "class": ('file-delete') }, {"title":true}));
buf.push('><span class="glyphicon glyphicon-remove-circle"></span></a><a');
buf.push(attrs({ 'href':("folders/" + (model.id) + "/zip/" + (model.name) + ""), 'target':("_blank"), 'title':("" + (t('tooltip download')) + ""), "class": ('file-download') }, {"href":true,"target":true,"title":true}));
buf.push('><span class="glyphicon glyphicon-cloud-download"></span></a></div><ul class="tags">');
if ( model.tags)
{
// iterate model.tags
;(function(){
  if ('number' == typeof model.tags.length) {

    for (var $index = 0, $$l = model.tags.length; $index < $$l; $index++) {
      var tag = model.tags[$index];

buf.push('<li>' + escape((interp = tag) == null ? '' : interp) + '</li>');
    }

  } else {
    var $$l = 0;
    for (var $index in model.tags) {
      $$l++;      var tag = model.tags[$index];

buf.push('<li>' + escape((interp = tag) == null ? '' : interp) + '</li>');
    }

  }
}).call(this);

}
buf.push('</ul></td><td class="size-column-cell"></td><td class="type-column-cell"><span class="pull-left">' + escape((interp = t('folder')) == null ? '' : interp) + '</span></td><td class="date-column-cell">');
if ( model.lastModification)
{
buf.push('<span>' + escape((interp = moment(model.lastModification).calendar()) == null ? '' : interp) + '</span>');
}
buf.push('</td>');
}
else
{
buf.push('<td><div class="caption-wrapper"><a');
buf.push(attrs({ 'href':("files/" + (model.id) + "/attach/" + (model.name) + ""), 'title':("" + (t('download file')) + ""), 'target':("_blank"), "class": ('caption') + ' ' + ('btn') + ' ' + ('btn-link') }, {"href":true,"title":true,"target":true}));
buf.push('><i class="fa fa-file-o"></i>' + escape((interp = model.name) == null ? '' : interp) + '</a></div><div class="operations"><a');
buf.push(attrs({ 'title':("" + (t('tooltip share')) + ""), "class": ('file-share') }, {"title":true}));
buf.push('>');
if ( model.clearance == 'public')
{
buf.push('<span class="fa fa-globe"></span>');
}
else if ( model.clearance && model.clearance.length > 0)
{
buf.push('<span class="fa fa-users">' + escape((interp = model.clearance.length) == null ? '' : interp) + '</span>');
}
else
{
buf.push('<span class="fa fa-lock"></span>');
}
buf.push('</a><a class="file-edit"><span');
buf.push(attrs({ 'title':("" + (t('tooltip edit')) + ""), "class": ('glyphicon') + ' ' + ('glyphicon-edit') }, {"title":true}));
buf.push('></span></a><a');
buf.push(attrs({ 'href':("files/" + (model.id) + "/download/" + (model.name) + ""), 'download':("" + (model.name) + ""), 'title':("" + (t('tooltip download')) + ""), "class": ('file-download') }, {"href":true,"download":true,"title":true}));
buf.push('><span class="glyphicon glyphicon-cloud-download"></span></a><a');
buf.push(attrs({ 'title':("" + (t('tooltip delete')) + ""), "class": ('file-delete') }, {"title":true}));
buf.push('><span class="glyphicon glyphicon-remove-circle"></span></a></div><ul class="tags">');
if ( model.tags)
{
// iterate model.tags
;(function(){
  if ('number' == typeof model.tags.length) {

    for (var $index = 0, $$l = model.tags.length; $index < $$l; $index++) {
      var tag = model.tags[$index];

buf.push('<li>' + escape((interp = tag) == null ? '' : interp) + '</li>');
    }

  } else {
    var $$l = 0;
    for (var $index in model.tags) {
      $$l++;      var tag = model.tags[$index];

buf.push('<li>' + escape((interp = tag) == null ? '' : interp) + '</li>');
    }

  }
}).call(this);

}
buf.push('</ul></td><td class="file-size size-column-cell">');
 options = {base: 2}
buf.push('<span>' + escape((interp = filesize(model.size || 0, options)) == null ? '' : interp) + '</span></td><td class="file-type type-column-cell"><span>' + escape((interp = t(model.class)) == null ? '' : interp) + '</span></td><td class="file-date date-column-cell">');
if ( model.lastModification)
{
buf.push('<span>' + escape((interp = moment(model.lastModification).calendar()) == null ? '' : interp) + '</span>');
}
buf.push('</td>');
}
}
return buf.join("");
};
});

;require.register("views/templates/file_edit", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<td><span class="caption caption-edit">');
if ( model.type && model.type == "folder")
{
buf.push('<i class="fa fa-folder"></i>');
}
else
{
buf.push('<i class="fa fa-file-o"></i>');
}
buf.push('<input');
buf.push(attrs({ 'value':(model.name), "class": ('caption') + ' ' + ('file-edit-name') }, {"value":true}));
buf.push('/></span><a class="btn btn-sm btn-cozy file-edit-save">' + escape((interp = t("file edit save")) == null ? '' : interp) + '</a><a class="btn btn-sm btn-link file-edit-cancel">' + escape((interp = t("file edit cancel")) == null ? '' : interp) + '</a></td><td class="file-size">');
 options = {base: 2}
buf.push('<span class="pull-left">' + escape((interp = filesize(model.size || 0, options)) == null ? '' : interp) + '</span></td><td class="file-type type-column-cell"><span class="pull-left">' + escape((interp = t(model.class)) == null ? '' : interp) + '</span></td><td class="file-date date-column-cell">');
if ( model.lastModification)
{
buf.push('<span class="pull-left">' + escape((interp = moment(model.lastModification).calendar()) == null ? '' : interp) + '</span>');
}
buf.push('</td>');
}
return buf.join("");
};
});

;require.register("views/templates/file_search", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
if ( model.type && model.type == "folder")
{
buf.push('<td><div class="caption-wrapper"><a');
buf.push(attrs({ 'href':("#folders/" + (model.id) + ""), 'title':("" + (t('open folder')) + ""), "class": ('caption') + ' ' + ('btn') + ' ' + ('btn-link') }, {"href":true,"title":true}));
buf.push('><i class="fa fa-folder"></i>' + escape((interp = model.name) == null ? '' : interp) + '</a></div><div class="operations"><a');
buf.push(attrs({ 'title':("" + (t('tooltip share')) + ""), "class": ('file-share') }, {"title":true}));
buf.push('>');
if ( model.clearance == 'public')
{
buf.push('<span class="fa fa-globe"></span>');
}
else if ( model.clearance && model.clearance.length > 0)
{
buf.push('<span class="fa fa-users">' + escape((interp = model.clearance.length) == null ? '' : interp) + '</span>');
}
else
{
buf.push('<span class="fa fa-lock"></span>');
}
buf.push('</a><a');
buf.push(attrs({ 'title':("" + (t('tooltip edit')) + ""), "class": ('file-edit') }, {"title":true}));
buf.push('><span class="glyphicon glyphicon-edit"></span></a><a');
buf.push(attrs({ 'title':("" + (t('tooltip delete')) + ""), "class": ('file-delete') }, {"title":true}));
buf.push('><span class="glyphicon glyphicon-remove-circle"></span></a><a');
buf.push(attrs({ 'href':("folders/" + (model.id) + "/zip/" + (model.name) + ""), 'target':("_blank"), 'title':("" + (t('tooltip download')) + ""), "class": ('file-download') }, {"href":true,"target":true,"title":true}));
buf.push('><span class="glyphicon glyphicon-cloud-download"></span></a></div><ul class="tags">');
if ( model.tags)
{
// iterate model.tags
;(function(){
  if ('number' == typeof model.tags.length) {

    for (var $index = 0, $$l = model.tags.length; $index < $$l; $index++) {
      var tag = model.tags[$index];

buf.push('<li>' + escape((interp = tag) == null ? '' : interp) + '</li>');
    }

  } else {
    var $$l = 0;
    for (var $index in model.tags) {
      $$l++;      var tag = model.tags[$index];

buf.push('<li>' + escape((interp = tag) == null ? '' : interp) + '</li>');
    }

  }
}).call(this);

}
buf.push('</ul><p class="file-path">' + escape((interp = model.path) == null ? '' : interp) + '/' + escape((interp = model.name) == null ? '' : interp) + '</p></td><td class="size-column-cell"></td><td class="type-column-cell"><span class="pull-left">' + escape((interp = t('folder')) == null ? '' : interp) + '</span></td><td class="date-column-cell">');
if ( model.lastModification)
{
buf.push('<span>' + escape((interp = moment(model.lastModification).calendar()) == null ? '' : interp) + '</span>');
}
buf.push('</td>');
}
else
{
buf.push('<td><div class="caption-wrapper"><a');
buf.push(attrs({ 'href':("files/" + (model.id) + "/attach/" + (model.name) + ""), 'title':("" + (t('download file')) + ""), 'target':("_blank"), "class": ('caption') + ' ' + ('btn') + ' ' + ('btn-link') }, {"href":true,"title":true,"target":true}));
buf.push('><i class="fa fa-file-o"></i>' + escape((interp = model.name) == null ? '' : interp) + '</a></div><div class="operations"><a');
buf.push(attrs({ 'title':("" + (t('tooltip share')) + ""), "class": ('file-share') }, {"title":true}));
buf.push('>');
if ( model.clearance == 'public')
{
buf.push('<span class="fa fa-globe"></span>');
}
else if ( model.clearance && model.clearance.length > 0)
{
buf.push('<span class="fa fa-users">' + escape((interp = model.clearance.length) == null ? '' : interp) + '</span>');
}
else
{
buf.push('<span class="fa fa-lock"></span>');
}
buf.push('</a><a class="file-edit"><span');
buf.push(attrs({ 'title':("" + (t('tooltip edit')) + ""), "class": ('glyphicon') + ' ' + ('glyphicon-edit') }, {"title":true}));
buf.push('></span></a><a');
buf.push(attrs({ 'href':("files/" + (model.id) + "/download/" + (model.name) + ""), 'download':("" + (model.name) + ""), 'title':("" + (t('tooltip download')) + ""), "class": ('file-download') }, {"href":true,"download":true,"title":true}));
buf.push('><span class="glyphicon glyphicon-cloud-download"></span></a><a');
buf.push(attrs({ 'title':("" + (t('tooltip delete')) + ""), "class": ('file-delete') }, {"title":true}));
buf.push('><span class="glyphicon glyphicon-remove-circle"></span></a></div><ul class="tags">');
if ( model.tags)
{
// iterate model.tags
;(function(){
  if ('number' == typeof model.tags.length) {

    for (var $index = 0, $$l = model.tags.length; $index < $$l; $index++) {
      var tag = model.tags[$index];

buf.push('<li>' + escape((interp = tag) == null ? '' : interp) + '</li>');
    }

  } else {
    var $$l = 0;
    for (var $index in model.tags) {
      $$l++;      var tag = model.tags[$index];

buf.push('<li>' + escape((interp = tag) == null ? '' : interp) + '</li>');
    }

  }
}).call(this);

}
buf.push('</ul><p class="file-path">' + escape((interp = model.path) == null ? '' : interp) + '/' + escape((interp = model.name) == null ? '' : interp) + '</p></td><td class="file-size size-column-cell">');
 options = {base: 2}
buf.push('<span>' + escape((interp = filesize(model.size || 0, options)) == null ? '' : interp) + '</span></td><td class="file-type type-column-cell"><span>' + escape((interp = t(model.class)) == null ? '' : interp) + '</span></td><td class="file-date date-column-cell">');
if ( model.lastModification)
{
buf.push('<span>' + escape((interp = moment(model.lastModification).calendar()) == null ? '' : interp) + '</span>');
}
buf.push('</td>');
}
}
return buf.join("");
};
});

;require.register("views/templates/files", function(exports, require, module) {
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

;require.register("views/templates/folder", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div id="dialog-upload-file" tabindex="-1" class="modal fade"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button><h4 class="modal-title">' + escape((interp = t("upload caption")) == null ? '' : interp) + '</h4></div><div class="modal-body"><fieldset><div class="form-group"><label for="uploader">' + escape((interp = t("upload msg")) == null ? '' : interp) + '</label><input id="uploader" type="file" multiple="multiple" class="form-control"/></div></fieldset></div><div class="modal-footer"><button id="cancel-new-file" type="button" data-dismiss="modal" class="btn btn-link">' + escape((interp = t("upload close")) == null ? '' : interp) + '</button><button id="upload-file-send" type="button" class="btn btn-cozy-contrast">' + escape((interp = t("upload send")) == null ? '' : interp) + '</button></div></div></div></div><div id="dialog-new-folder" tabindex="-1" class="modal fade"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button><h4 class="modal-title">' + escape((interp = t("new folder caption")) == null ? '' : interp) + '</h4></div><div class="modal-body"><fieldset><div class="form-group"><label for="inputName">' + escape((interp = t("new folder msg")) == null ? '' : interp) + '</label><input id="inputName" type="text" class="form-control"/></div><div id="folder-upload-form" class="form-group hide"><br/><p class="text-center">or</p><label for="inputName">' + escape((interp = t("upload folder msg")) == null ? '' : interp) + '</label><input id="folder-uploader" type="file" directory="directory" mozdirectory="mozdirectory" webkitdirectory="webkitdirectory" class="form-control"/></div></fieldset></div><div class="modal-footer"><button id="cancel-new-folder" type="button" data-dismiss="modal" class="btn btn-link">' + escape((interp = t("new folder close")) == null ? '' : interp) + '</button><button id="new-folder-send" type="button" class="btn btn-cozy">' + escape((interp = t("new folder send")) == null ? '' : interp) + '</button></div></div></div></div><div id="affixbar" data-spy="affix" data-offset-top="1"><div class="container"><div class="row"><div class="col-lg-12"><div id="crumbs" class="pull-left"></div><p class="pull-right"><input id="search-box" type="search" class="pull-right"/></p><p class="pull-right"><a id="button-upload-new-file" data-toggle="modal" data-target="#dialog-upload-file" class="btn btn-cozy"><img src="images/add-file.png"/></a>&nbsp;<a id="button-new-folder" data-toggle="modal" data-target="#dialog-new-folder" class="btn btn-cozy"><img src="images/add-folder.png"/></a></p></div></div></div></div><div class="container"><div class="row content-shadow"><div id="content" class="col-lg-12"><div id="loading-indicator"></div><table id="table-items" class="table table-hover"><tbody id="table-items-body"><tr class="table-headers"><td><span>');
var __val__ = t('name')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</span><a id="down-name" class="btn glyphicon glyphicon-chevron-down"></a><a id="up-name" class="btn glyphicon glyphicon-chevron-up"></a></td><td class="size-column-cell"><span>');
var __val__ = t('size')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</span><a id="down-size" class="glyphicon glyphicon-chevron-down btn"></a><a id="up-size" class="unactive btn glyphicon glyphicon-chevron-up"></a></td><td class="type-column-cell"><span>');
var __val__ = t('type')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</span><a id="down-class" class="btn glyphicon glyphicon-chevron-down"></a><a id="up-class" class="glyphicon glyphicon-chevron-up btn unactive"></a></td><td class="date-column-cell"><span>');
var __val__ = t('date')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</span><a id="down-lastModification" class="btn glyphicon glyphicon-chevron-down"></a><a id="up-lastModification" class="btn glyphicon glyphicon-chevron-up unactive"></a></td></tr></tbody></table><div id="files"></div></div></div></div>');
}
return buf.join("");
};
});

;require.register("views/templates/modal", function(exports, require, module) {
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

;require.register("views/templates/progressbar", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="progress active"><div');
buf.push(attrs({ 'role':("progressbar"), 'aria-valuenow':("" + (value) + ""), 'aria-valuemin':("0"), 'aria-valuemax':("100"), 'style':("width: " + (value) + "%"), "class": ('progress-bar') + ' ' + ('progress-bar-info') }, {"role":true,"aria-valuenow":true,"aria-valuemin":true,"aria-valuemax":true,"style":true}));
buf.push('></div></div>');
}
return buf.join("");
};
});

;
//# sourceMappingURL=app.js.map