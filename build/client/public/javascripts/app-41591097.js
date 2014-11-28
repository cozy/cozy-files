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
var File, FileCollection, FolderView, SocketListener, UploadQueue;

FileCollection = require('./collections/files');

UploadQueue = require('./collections/upload_queue');

File = require('./models/file');

SocketListener = require('../lib/socket');

FolderView = require('./views/folder');


/*
Initialize the model and start the actual code
 */

module.exports = {
  initialize: function() {
    var Router;
    this.isPublic = window.location.pathname.indexOf('/public/') === 0;
    this.baseCollection = new FileCollection();
    this.uploadQueue = new UploadQueue();
    this.socket = new SocketListener();
    this.socket.watch(this.baseCollection);
    Router = require('router');
    this.router = new Router();
    if (window.rootFolder != null) {
      this.root = new File(window.rootFolder);
      this.root.canUpload = window.canUpload || false;
      this.root.publicNotificationsEnabled = window.publicNofications || false;
      this.root.publicKey = window.publicKey || "";
    } else {
      this.root = new File({
        id: "root",
        path: "",
        name: t('root folder name'),
        type: "folder"
      });
    }
    this.baseCollection.add(this.root);
    window.app = this;
    Backbone.history.start();
    if (typeof Object.freeze === 'function') {
      return Object.freeze(this);
    }
  }
};
});

;require.register("initialize", function(exports, require, module) {
var app;

app = require('application');

$(function() {
  var err, locale, locales, polyglot;
  jQuery.event.props.push('dataTransfer');
  locale = window.locale || "en";
  moment.lang(locale);
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
  window.pendingOperations = {
    upload: 0,
    move: 0,
    deletion: 0
  };
  return app.initialize();
});

window.onbeforeunload = function() {
  var pendingOperationsNum, sum, values;
  values = _.values(window.pendingOperations);
  sum = function(a, b) {
    return a + b;
  };
  pendingOperationsNum = _.reduce(values, sum, 0);
  if (pendingOperationsNum > 0) {
    return t('confirmation reload');
  }
};
});

;require.register("router", function(exports, require, module) {
var File, FileCollection, FolderView, MergedCollection, PublicFolderView, Router, app,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

app = require('application');

File = require('./models/file');

FileCollection = require('./collections/files');

MergedCollection = require('./lib/merged_collection');

FolderView = require('./views/folder');

PublicFolderView = require('./views/public_folder');


/*
Binds routes to code actions.
This is also used as a controller to initialize views and perform data fetching
 */

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.folderView = null;

  Router.prototype.routes = {
    '': 'main',
    'folders/:folderid': 'folder',
    'search/:query': 'search'
  };

  Router.prototype.main = function() {
    var rootID;
    rootID = app.root.get('id');
    return this._loadFolderView(rootID);
  };

  Router.prototype.folder = function(id) {
    return this._loadFolderView(id);
  };

  Router.prototype.search = function(query) {
    var folder;
    folder = new File({
      id: query,
      type: "search",
      name: "" + (t('breadcrumbs search title')) + " '" + query + "'"
    });
    return folder.fetchContent((function(_this) {
      return function(err, content) {
        var collection;
        collection = new FileCollection(content);
        if (_this.folderView != null) {
          return _this.folderView.updateSearch(folder, collection);
        } else {
          return _this._renderFolderView(folder, collection, query);
        }
      };
    })(this));
  };

  Router.prototype._loadFolderView = function(folderID) {
    if (this.folderView != null) {
      this.folderView.spin();
    }
    return app.baseCollection.getByFolder(folderID, (function(_this) {
      return function(err, folder, collection) {
        if (err != null) {
          return console.log(err);
        } else {
          return _this._renderFolderView(folder, collection);
        }
      };
    })(this));
  };

  Router.prototype._renderFolderView = function(folder, collection, query) {
    var filteredUploads, mergedCollection;
    if (query == null) {
      query = '';
    }
    if (this.folderView != null) {
      this.folderView.destroy();
      $('html').append($('<body></body>'));
    }
    filteredUploads = app.uploadQueue.filteredByFolder(folder, collection.comparator);
    mergedCollection = MergedCollection(collection, filteredUploads, 'name');
    this.folderView = this._getFolderView({
      model: folder,
      collection: mergedCollection,
      baseCollection: app.baseCollection,
      breadcrumbs: app.breadcrumbs,
      uploadQueue: app.uploadQueue,
      query: query
    });
    return this.folderView.render();
  };

  Router.prototype._getFolderView = function(params) {
    if (app.isPublic) {
      return new PublicFolderView(_.extend(params, {
        rootFolder: app.root
      }));
    } else {
      return new FolderView(params);
    }
  };

  return Router;

})(Backbone.Router);
});

;
//# sourceMappingURL=app.js.map