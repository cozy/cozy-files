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

;require.register("collections/files", function(exports, require, module) {
var File, FileCollection,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

File = require('../models/file');


/*
Represents a collection of files
It acts as the cache when instantiate as the baseCollection
The base collection holds ALL the files and folders of the application
It creates projections (subcollection) that will be consumed by folder views.
Those projections represents one folder.
 */

module.exports = FileCollection = (function(_super) {
  __extends(FileCollection, _super);

  function FileCollection() {
    return FileCollection.__super__.constructor.apply(this, arguments);
  }

  FileCollection.prototype.model = File;

  FileCollection.prototype.url = 'files';

  FileCollection.prototype.cachedPaths = [];

  FileCollection.prototype.isPathCached = function(path) {
    return this.cachedPaths.indexOf(path) !== -1;
  };


  /*
      Retrieves folder's information (meta data)
      * from memory if it's cached
      * otherwise, from server
   */

  FileCollection.prototype.getFolderInfo = function(folderID, callback) {
    var folder;
    folder = this.get(folderID);
    if (folder == null) {
      folder = new File({
        id: folderID,
        type: "folder"
      });
      return folder.fetch({
        success: (function(_this) {
          return function() {
            _this.add(folder);
            return callback(null, folder);
          };
        })(this),
        error: function(xhr, resp) {
          return callback({
            status: resp.status,
            msg: resp.statusText
          });
        }
      });
    } else {
      return callback(null, folder);
    }
  };

  FileCollection.prototype.getFolderContent = function(folder, callback) {
    var path;
    if (callback == null) {
      callback = function() {};
    }
    path = folder.getRepository();
    return folder.fetchContent((function(_this) {
      return function(err, content, parents) {
        var contentIDs, itemsToRemove;
        if (err != null) {
          return callback(err);
        } else {
          _this.set(content, {
            remove: false
          });
          contentIDs = _.pluck(content, 'id');
          path = folder.getRepository();
          itemsToRemove = _this.getSubCollection(path).filter(function(item) {
            var _ref;
            return _ref = item.get('id'), __indexOf.call(contentIDs, _ref) < 0;
          });
          _this.remove(itemsToRemove);
          if (!_this.isPathCached(path)) {
            _this.cachedPaths.push(path);
          }
          return callback();
        }
      };
    })(this));
  };


  /*
      Global method to retrieve folder's info and content
      and create a subcollection (projection) based on the current collection
   */

  FileCollection.prototype.getByFolder = function(folderID, callback) {
    return this.getFolderInfo(folderID, (function(_this) {
      return function(err, folder) {
        var collection, filter, path;
        if (err != null) {
          return callback(err);
        } else {
          path = folder.getRepository();
          filter = function(file) {
            return file.get('path') === path && !file.isRoot();
          };
          collection = new BackboneProjections.Filtered(_this, {
            filter: filter,
            comparator: _this.comparator
          });
          if (_this.isPathCached(path)) {
            return callback(null, folder, collection);
          } else {
            return _this.getFolderContent(folder, function() {
              return callback(null, folder, collection);
            });
          }
        }
      };
    })(this));
  };

  FileCollection.prototype.existingPaths = function() {
    return this.map(function(model) {
      return model.getRepository();
    });
  };

  FileCollection.prototype.getSubCollection = function(path) {
    var filter;
    filter = function(file) {
      return file.get('path') === path && !file.isRoot();
    };
    return new BackboneProjections.Filtered(this, {
      filter: filter,
      comparator: this.comparator
    });
  };

  FileCollection.prototype.comparator = function(f1, f2) {
    var e1, e2, n1, n2, sort, t1, t2;
    if (this.type == null) {
      this.type = 'name';
    }
    if (this.order == null) {
      this.order = 'asc';
    }
    t1 = f1.get('type');
    t2 = f2.get('type');
    if (f1.isFolder() && !f2.isFolder() && f1.isNew()) {
      return -1;
    }
    if (f2.isFolder() && !f1.isFolder() && f2.isNew()) {
      return 1;
    }
    if (this.type === 'name') {
      n1 = f1.get('name').toLocaleLowerCase();
      n2 = f2.get('name').toLocaleLowerCase();
    } else if (this.type === "lastModification") {
      n1 = new Date(f1.get('lastModification')).getTime();
      n2 = new Date(f2.get('lastModification')).getTime();
    } else {
      n1 = f1.get(this.type);
      n2 = f2.get(this.type);
    }
    sort = this.order === 'asc' ? -1 : 1;
    if (t1 === t2) {
      if (this.type === 'class' && n1 === n2) {
        n1 = f1.get('name').toLocaleLowerCase();
        n2 = f2.get('name').toLocaleLowerCase();
        e1 = n1.split('.').pop();
        e2 = n2.split('.').pop();
        if (e1 !== e2) {
          if (e1 > e2) {
            return -sort;
          }
          if (e1 < e2) {
            return sort;
          }
          return 0;
        }
      }
      if (n1 > n2) {
        return -sort;
      } else if (n1 < n2) {
        return sort;
      } else {
        return 0;
      }
    } else if (t1 === 'file' && t2 === 'folder') {
      return 1;
    } else {
      return -1;
    }
  };

  return FileCollection;

})(Backbone.Collection);
});

;require.register("collections/upload_queue", function(exports, require, module) {
var File, Helpers, UploadQueue,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

File = require('../models/file');

Helpers = require('../lib/folder_helpers');

module.exports = UploadQueue = (function(_super) {
  __extends(UploadQueue, _super);

  function UploadQueue() {
    this.uploadWorker = __bind(this.uploadWorker, this);
    this.sumProp = __bind(this.sumProp, this);
    this.computeProgress = __bind(this.computeProgress, this);
    return UploadQueue.__super__.constructor.apply(this, arguments);
  }

  UploadQueue.prototype.loaded = 0;

  UploadQueue.prototype.uploadingPaths = {};

  UploadQueue.prototype.initialize = function() {
    this.asyncQueue = async.queue(this.uploadWorker, 5);
    this.listenTo(this, 'add', (function(_this) {
      return function(model) {
        _this.completed = false;
        if (model.get('type') === 'file') {
          if (model.conflict) {
            return _this.asyncQueue.push(model);
          } else {
            return _this.asyncQueue.unshift(model);
          }
        } else if (model.get('type') === 'folder') {
          return _this.asyncQueue.unshift(model);
        } else {
          throw new Error('adding wrong typed model to upload queue');
        }
      };
    })(this));
    this.listenTo(this, 'remove', (function(_this) {
      return function(model) {
        return model.error = 'aborted';
      };
    })(this));
    this.listenTo(this, 'sync error', (function(_this) {
      return function(model) {
        var path;
        path = model.get('path') + '/';
        _this.uploadingPaths[path]--;
        return _this.loaded++;
      };
    })(this));
    this.listenTo(this, 'progress', _.throttle((function(_this) {
      return function() {
        return _this.trigger('upload-progress', _this.computeProgress());
      };
    })(this), 100));
    return this.asyncQueue.drain = (function(_this) {
      return function() {
        window.pendingOperations.upload = 0;
        _this.completed = true;
        _this.loaded = 0;
        return _this.trigger('upload-complete');
      };
    })(this);
  };

  UploadQueue.prototype.add = function(models, options) {
    if (models != null) {
      window.pendingOperations.upload++;
    }
    if (this.completed) {
      this.reset();
    }
    return UploadQueue.__super__.add.call(this, models, options);
  };

  UploadQueue.prototype.reset = function(models, options) {
    this.progress = {
      loadedFiles: 0,
      totalFiles: this.length,
      loadedBytes: 0,
      totalBytes: this.sumProp('total')
    };
    window.pendingOperations.upload = 0;
    this.loaded = 0;
    this.completed = false;
    this.uploadingPaths = {};
    return UploadQueue.__super__.reset.apply(this, arguments);
  };

  UploadQueue.prototype.computeProgress = function() {
    return this.progress = {
      loadedFiles: this.loaded,
      totalFiles: this.length,
      loadedBytes: this.sumProp('loaded'),
      totalBytes: this.sumProp('total')
    };
  };

  UploadQueue.prototype.sumProp = function(prop) {
    var iter;
    iter = function(sum, model) {
      return sum + model[prop];
    };
    return this.reduce(iter, 0);
  };

  UploadQueue.prototype.uploadWorker = function(model, cb) {
    var processSave;
    if (model.existing || model.error || model.isUploaded) {
      return setTimeout(cb, 10);
    } else {
      processSave = function(model) {
        if (!model.conflict || model.conflict && model.overwrite) {
          return model.save(null, {
            success: function() {
              model.file = null;
              model.isUploaded = true;
              model.loaded = model.total;
              if (!app.baseCollection.get(model.id)) {
                app.baseCollection.add(model);
              }
              return cb(null);
            },
            error: (function(_this) {
              return function(_, err) {
                var body, defaultMessage, e;
                body = (function() {
                  try {
                    return JSON.parse(err.responseText);
                  } catch (_error) {
                    e = _error;
                    return {
                      msg: null
                    };
                  }
                })();
                if (err.status === 400 && body.code === 'EEXISTS') {
                  model.existing = true;
                  return cb(new Error(body.msg));
                }
                if (err.status === 400 && body.code === 'ESTORAGE') {
                  model.error = new Error(body.msg);
                  return cb(model.error);
                }
                model.tries = 1 + (model.tries || 0);
                if (model.tries > 3) {
                  defaultMessage = "modal error file upload";
                  model.error = t(err.msg || defaultMessage);
                } else {
                  _this.asyncQueue.push(model);
                }
                return cb(err);
              };
            })(this)
          });
        } else {
          return cb();
        }
      };
      if (model.conflict && (model.overwrite == null)) {
        return model.processSave = processSave.bind(this);
      } else {
        return processSave.call(this, model);
      }
    }
  };

  UploadQueue.prototype.addBlobs = function(blobs, folder) {
    var existingPaths, i, nonBlockingLoop;
    i = 0;
    existingPaths = app.baseCollection.existingPaths();
    return (nonBlockingLoop = (function(_this) {
      return function() {
        var blob, model, path, relPath, subDir, _ref;
        if (!(blob = blobs[i++])) {
          return;
        }
        path = folder.getRepository() || '';
        relPath = blob.relativePath || blob.mozRelativePath || blob.webkitRelativePath || blob.msRelativePath;
        if (relPath && (subDir = Helpers.dirName(relPath)).length > 0) {
          path += "/" + subDir;
        }
        model = new File({
          type: 'file',
          "class": 'document',
          size: blob.size,
          name: blob.name,
          path: path,
          lastModification: blob.lastModifiedDate
        });
        if (blob.size === 0 && blob.type.length === 0) {
          model.error = 'Cannot upload a folder with Firefox';
          model.loaded = 0;
          model.total = 0;
        } else if (_ref = model.getRepository(), __indexOf.call(existingPaths, _ref) >= 0) {
          model.conflict = true;
          _this.trigger('conflict', model);
          model.file = blob;
          model.loaded = 0;
          model.total = blob.size;
        } else {
          model.file = blob;
          model.loaded = 0;
          model.total = blob.size;
        }
        _this.add(model);
        _this.markAsBeingUploaded(model);
        return setTimeout(nonBlockingLoop, 2);
      };
    })(this))();
  };

  UploadQueue.prototype.addFolderBlobs = function(blobs, parent) {
    var dirs, i, nonBlockingLoop;
    dirs = Helpers.nestedDirs(blobs);
    i = 0;
    return (nonBlockingLoop = (function(_this) {
      return function() {
        var dir, folder, name, parts, path, prefix;
        if (!(dir = dirs[i++])) {
          blobs = _.filter(blobs, function(blob) {
            var _ref;
            return (_ref = blob.name) !== '.' && _ref !== '..';
          });
          _this.addBlobs(blobs, parent);
          return;
        }
        prefix = parent.getRepository();
        parts = dir.split('/').filter(function(x) {
          return x;
        });
        name = parts[parts.length - 1];
        path = [prefix].concat(parts.slice(0, -1)).join('/');
        folder = new File({
          type: "folder",
          name: name,
          path: path
        });
        folder.loaded = 0;
        folder.total = 250;
        _this.add(folder);
        _this.markAsBeingUploaded(folder);
        return setTimeout(nonBlockingLoop, 2);
      };
    })(this))();
  };

  UploadQueue.prototype.filteredByFolder = function(folder, comparator) {
    var filteredUploads;
    return filteredUploads = new BackboneProjections.Filtered(this, {
      filter: function(file) {
        return file.get('path') === folder.getRepository() && !file.isUploaded;
      },
      comparator: comparator
    });
  };

  UploadQueue.prototype.getResults = function() {
    var error, existing, skipped, status, success;
    error = [];
    existing = [];
    success = 0;
    skipped = 0;
    this.each(function(model) {
      if (model.error) {
        console.log("Upload Error", model.getRepository(), model.error);
        return error.push(model);
      } else if (model.existing) {
        return existing.push(model);
      } else if (model.conflict && !model.overwrite) {
        return skipped++;
      } else {
        return success++;
      }
    });
    status = error.length ? 'error' : existing.length ? 'warning' : 'success';
    return {
      status: status,
      error: error,
      existing: existing,
      success: success,
      skipped: skipped
    };
  };

  UploadQueue.prototype.markAsBeingUploaded = function(model) {
    var path;
    path = model.get('path') + '/';
    if (this.uploadingPaths[path] == null) {
      this.uploadingPaths[path] = 0;
    }
    return this.uploadingPaths[path]++;
  };

  UploadQueue.prototype.getNumUploadingElementsByPath = function(path) {
    path = path + '/';
    return _.reduce(this.uploadingPaths, function(memo, value, index) {
      if (index.indexOf(path) !== -1 || path === '') {
        return memo + value;
      } else {
        return memo;
      }
    }, 0);
  };

  return UploadQueue;

})(Backbone.Collection);
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
  require("./utils/plugin_utils").init();
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
    return this.remove();
  };

  return BaseView;

})(Backbone.View);
});

;require.register("lib/client", function(exports, require, module) {
exports.request = function(type, url, data, callback) {
  return $.ajax({
    type: type,
    url: url,
    data: data != null ? JSON.stringify(data) : null,
    contentType: "application/json",
    dataType: "json",
    success: function(data) {
      if (callback != null) {
        return callback(null, data);
      }
    },
    error: function(data) {
      var _ref;
      if ((_ref = data.status) === 200 || _ref === 201 || _ref === 204 || _ref === 304) {
        if (callback != null) {
          return callback(null, data);
        }
      } else if ((data != null) && (data.msg != null) && (callback != null)) {
        return callback(new Error(data.msg));
      } else if (callback != null) {
        return callback(new Error("Server error occured"));
      }
    }
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

;require.register("lib/folder_helpers", function(exports, require, module) {
var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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
    var addedPath, dir, dirs, file, foldersOfPath, parent, parents, relPath, _i, _len;
    dirs = [];
    addedPath = [];
    for (_i = 0, _len = fileList.length; _i < _len; _i++) {
      file = fileList[_i];
      relPath = file.relativePath || file.mozRelativePath || file.webkitRelativePath;
      parents = relPath.slice(0, relPath.lastIndexOf(file.name));
      foldersOfPath = parents.split('/').slice(0, -1);
      while (foldersOfPath.length > 0) {
        parent = foldersOfPath.join('/');
        if (!(__indexOf.call(addedPath, parent) >= 0)) {
          dirs.push({
            path: parent,
            depth: foldersOfPath.length
          });
          addedPath.push(parent);
          foldersOfPath.pop();
        } else {
          break;
        }
      }
    }
    dirs.sort(function(a, b) {
      return a.depth - b.depth;
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

;require.register("lib/merged_collection", function(exports, require, module) {
var MergedCollection,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

module.exports = MergedCollection = function(primary, secondary, uniqAttr) {
  var events, mixed, reset, sameAs;
  if (uniqAttr == null) {
    uniqAttr = 'id';
  }
  mixed = new Backbone.Collection([], {
    comparator: primary.comparator
  });
  mixed.Primary = primary;
  mixed.Secondary = secondary;
  (reset = function() {
    var ids, models;
    models = [];
    ids = [];
    primary.forEach(function(model) {
      models.push(model);
      return ids.push(model.id);
    });
    secondary.forEach(function(model) {
      var _ref;
      if (_ref = model.id, __indexOf.call(ids, _ref) < 0) {
        return models.push(model);
      }
    });
    return mixed.reset(models);
  })();
  sameAs = function(model, collection) {
    var search;
    search = {};
    search[uniqAttr] = model.get(uniqAttr);
    return collection.findWhere(search);
  };
  events = {
    reset: reset,
    remove: (function(_this) {
      return function(model, collection) {
        var other;
        other = collection === primary ? secondary : primary;
        return mixed.remove(model);
      };
    })(this),
    add: function(model, collection) {
      var existing;
      if (existing = sameAs(model, mixed)) {
        if (collection === primary || model.conflict) {
          mixed.remove(existing);
          return mixed.add(model);
        }
      } else {
        return mixed.add(model);
      }
    },
    'change:id': function(model) {
      var dups, toRemove;
      dups = mixed.where({
        id: model.id
      });
      if (dups.length === 2) {
        toRemove = dups[0].collection === secondary ? 0 : 1;
        return mixed.remove(dups[toRemove]);
      }
    },
    sort: function() {
      return mixed.sort();
    }
  };
  primary.bind(events);
  secondary.bind(events);
  return mixed;
};
});

;require.register("lib/socket", function(exports, require, module) {
var File, SocketListener, contactCollection,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

File = require('../models/file');

contactCollection = require('cozy-clearance/contact_collection');

module.exports = SocketListener = (function(_super) {
  __extends(SocketListener, _super);

  function SocketListener() {
    return SocketListener.__super__.constructor.apply(this, arguments);
  }

  SocketListener.prototype.models = {
    'file': File,
    'folder': File
  };

  SocketListener.prototype.events = ['file.create', 'file.update', 'file.delete', 'folder.create', 'folder.update', 'folder.delete', 'contact.create', 'contact.update', 'contact.delete'];

  SocketListener.prototype.isInCachedFolder = function(model) {
    var path;
    path = model.get('path');
    return this.collection.isPathCached(path);
  };

  SocketListener.prototype.onRemoteCreate = function(model) {
    if (this.isInCachedFolder(model)) {
      if (!(this.collection.get(model.get("id")))) {
        return this.collection.add(model, {
          merge: true
        });
      }
    }
  };

  SocketListener.prototype.onRemoteDelete = function(model) {
    if (this.isInCachedFolder(model)) {
      return this.collection.remove(model);
    }
  };

  SocketListener.prototype.onRemoteUpdate = function(model, collection) {
    if (this.isInCachedFolder(model)) {
      return collection.add(model, {
        merge: true
      });
    }
  };

  SocketListener.prototype.process = function(event) {
    var doctype, id, model, operation;
    doctype = event.doctype, operation = event.operation, id = event.id;
    if (doctype === 'contact') {
      return contactCollection.handleRealtimeContactEvent(event);
    } else {
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
    }
  };

  return SocketListener;

})(CozySocketListener);
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

  ViewCollection.prototype.collectionEl = null;

  ViewCollection.prototype.template = function() {
    return '';
  };

  ViewCollection.prototype.itemview = null;

  ViewCollection.prototype.views = {};

  ViewCollection.prototype.itemViewOptions = function() {};

  ViewCollection.prototype.bufferEl = null;

  ViewCollection.prototype.getItemViewSelector = function() {
    var classNames;
    classNames = this.itemview.prototype.className.replace(' ', '.');
    return "" + this.itemview.prototype.tagName + "." + classNames;
  };

  ViewCollection.prototype.onChange = function() {
    return this.$el.toggleClass('empty', _.size(this.views) === 0);
  };

  ViewCollection.prototype.appendView = function(view) {
    var brother, brotherAfter, index, selector;
    index = this.collection.indexOf(view.model);
    if (index === 0) {
      if (this.isBuffering) {
        $(this.bufferEl).prepend(view.$el);
      } else {
        this.$collectionEl.prepend(view.$el);
      }
    } else {
      if (this.isBuffering) {
        brother = this.bufferEl.childNodes[index - 1];
        if (brother != null) {
          brotherAfter = brother.nextSibling;
          this.bufferEl.insertBefore(view.el, brotherAfter);
        }
      } else {
        selector = this.getItemViewSelector();
        view.$el.insertAfter($(selector).eq(index - 1));
      }
    }

    /*
        If buffering is enabled, we batch all appendView to one DOM request
        thanks to a document fragment. Data are added one by one so we use
        a set timeout
     */
    if (this.isBuffering) {
      clearTimeout(this.timeout);
      return this.timeout = setTimeout((function(_this) {
        return function() {
          return _this.cleanBuffer();
        };
      })(this), 1);
    }
  };

  ViewCollection.prototype.initialize = function() {
    ViewCollection.__super__.initialize.apply(this, arguments);
    this.views = {};
    this.listenTo(this.collection, "reset", this.onReset);
    this.listenTo(this.collection, "add", this.addItem);
    this.listenTo(this.collection, "remove", this.removeItem);
    this.listenTo(this.collection, "sort", this.onSort);
    if (this.collectionEl == null) {
      this.collectionEl = el;
    }
    return this.initializeBuffering();
  };

  ViewCollection.prototype.initializeBuffering = function() {
    this.isBuffering = true;
    return this.bufferEl = document.createDocumentFragment();
  };

  ViewCollection.prototype.cleanBuffer = function() {
    if (this.isBuffering) {
      this.isBuffering = false;
      this.$collectionEl.html(this.bufferEl);
      return this.bufferEl = null;
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
    this.$collectionEl = $(this.collectionEl);
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
      this.removeItem(view.model);
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

  ViewCollection.prototype.onSort = function() {
    var $itemViews, orderChanged, selector;
    selector = this.getItemViewSelector();
    $itemViews = $(selector);
    orderChanged = this.collection.find((function(_this) {
      return function(item, index) {
        var indexView, view;
        view = _this.views[item.cid];
        indexView = $itemViews.index(view.$el);
        return view && indexView !== index;
      };
    })(this));
    if (orderChanged) {
      return this.render();
    }
  };

  return ViewCollection;

})(BaseView);
});

;require.register("locales/en", function(exports, require, module) {
module.exports = {
  "or": "or",
  "modal error": "Error",
  "modal ok": "OK",
  "modal error get files": "Error getting files from server",
  "modal error get folders": "Error getting folders from server",
  "modal error get content": "An error occurred while retrieving content of folder \"%{folderName}\" from the server",
  "modal error empty name": "The name can't be empty",
  "modal error file invalid": "doesn't seem to be a valid file",
  "root folder name": "root",
  "confirmation reload": "An operation is in progress, are you sure you want to reload the page?",
  "breadcrumbs search title": "Search",
  "modal error file exists": "Sorry, a file or folder having this name already exists",
  "modal error size": "Sorry, you haven't enough storage space",
  "modal error file upload": "File could not be sent to server",
  "modal error folder create": "Folder could not be created",
  "modal error folder exists": "Sorry, a file or folder having this name already exists",
  "modal error zip empty folder": "You can't download an empty folder as a ZIP.",
  "upload running": "Upload is progress. Do not close your browser",
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
  "tooltip tag": "Tag",
  'and x files': "and %{smart_count} other file ||||\nand %{smart_count} other files",
  "already exists": "already exists.",
  "failed to upload": "could not be sent to server.",
  "upload complete": "One file successfully uploaded. ||||\n%{smart_count} files successfully uploaded.",
  "chrome error dragdrop title": "Files are going to be ignored",
  "chrome error dragdrop content": "Due to a bug in Chrome, the following file: %{files} is going to be\nignored because it has an accent in its name. You can still add\nit by using the button on the top right of your screen. ||||\nDue to a bug in Chrome, the following files: %{files} are going to be\nignored because they have an accent in their name. You can still add\nthem by using the button on the top right of your screen.",
  "chrome error submit": "Ok",
  "upload caption": "Upload a new file",
  "upload msg": "Drag files or click here to choose files.",
  "upload msg selected": "You have selected %{smart_count} file, click Add to upload it. ||||\nYou have selected %{smart_count} files, click Add to upload them.",
  "upload close": "Close",
  "upload send": "Add",
  "upload button": "Upload a file",
  "upload success": "Upload successfuly completed!",
  "upload end button": "Close",
  "total progress": "Total progress",
  "new folder caption": "Add a new folder",
  "new folder msg": "Create a folder named:",
  "new folder close": "Close",
  "new folder send": "Create Folder",
  "new folder button": "Create a new folder",
  "new folder": "new folder",
  "download all": "Download the selection",
  "move all": "Move the selection",
  "remove all": "Remove the selection",
  "drop message": "Drop your files here to automatically add them",
  "upload folder msg": "Upload a folder",
  "upload folder separator": "or",
  "overwrite modal title": "A file already exist",
  "overwrite modal content": "Do you want to overwrite \"%{fileName}\"?",
  "overwrite modal remember label": "Apply this decision to all conflicts",
  "overwrite modal yes button": "Overwrite",
  "overwrite modal no button": "Skip",
  "folder": "Folder",
  "image": "Image",
  "document": "Document",
  "music": "Music",
  "video": "Video",
  "yes": "Yes",
  "no": "No",
  "ok": "Ok",
  "name": "Name",
  "type": "Type",
  "size": "Size",
  "date": "Last update",
  "download": "Download all",
  "MB": "MB",
  "KB": "KB",
  "B": "B",
  "files": "files",
  "element": "%{smart_count} element |||| %{smart_count} elements",
  "no file in folder": "This folder is empty.",
  "no file in search": "Your search did not match any documents.",
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
  "modal shared public link msg": "Send this link to let people access this folder:",
  "modal shared with people msg": "Give access to a selection of contacts. Type their emails or name in the field and press enter (an email will be sent to them when you will close this window):",
  "modal send mails": "Send a notification",
  "modal question file shareable": "Select share mode for this file",
  "modal shared file custom msg": "Enter email and press enter",
  "modal shared file link msg": "Send this link to let people access this file",
  "only you can see": "Only you can access this resource",
  "public": "Public",
  "private": "Private",
  "shared": "Shared",
  "share": "Share",
  "save": "Save",
  "see link": "See link",
  "send mails question": "Send a notification email to:",
  "sharing": "Sharing",
  "revoke": "Revoke",
  "forced public": "The current file/folder is shared because one of its parent folders is shared.",
  "forced shared": "The current file/folder is shared because one of its parent folders is shared. Here is the list of guests who can access it:",
  "confirm": "Confirm",
  "share forgot add": "Looks like you forgot to click the Add button",
  "share confirm save": "The changes you made to the permissions will not be saved. Is that what you want ?",
  "yes forgot": "Back",
  "no forgot": "It's ok",
  "perm": "can ",
  "perm r file": "download this file",
  "perm r folder": "browse this folder",
  "perm rw folder": "browse and upload files",
  "change notif": "Check this box to be notified when a contact\nadd a file to this folder.",
  "send email hint": "Notification emails will be sent one time on save",
  'move': 'Move',
  'tooltip move': 'Move element to another folder.',
  "moving...": 'Moving...',
  'move element to': 'Move element to',
  'error occured canceling move': 'An error occured while canceling move.',
  'error occured while moving element': 'An error occured while moving element',
  'file successfully moved to': 'File successfully moved to',
  'plugin modal close': 'Close',
  'moving selected elements': 'Moving selected elements',
  'move elements to': "Move elements to",
  "elements successfully moved to": 'Elements successfully moved to',
  'close': 'Close'
};
});

;require.register("locales/fr", function(exports, require, module) {
module.exports = {
  "or": "ou",
  "modal error": "Erreur",
  "modal ok": "OK",
  "modal error get files": "Une erreur s'est produite en récupérant les fichiers du serveur",
  "modal error get folders": "Une erreur s'est produite en récupérant les dossiers du serveur",
  "modal error get content": "Une erreur s'est produite en récupérant le contenu du dossier \"%{folderName}\" sur le serveur",
  "modal error empty name": "Le nom ne peut pas être vide",
  "modal error file invalid": "Le fichier ne parait pas être valide",
  "root folder name": "racine",
  "confirmation reload": "Une opération est en cours. Êtes-vous sûr(e) de vouloir recharger la page ?",
  "breadcrumbs search title": "Recherche",
  "modal error file exists": "Désolé, un fichier ou un dossier a déjà le même nom",
  "modal error size": "Désolé, vous n'avez pas assez d'espace de stockage",
  "modal error file upload": "Le fichier n'a pas pu être envoyé au serveur",
  "modal error folder create": "Le dossier n'a pas pu être créé",
  "modal error folder exists": "Désolé, un fichier ou un dossier a déjà le même nom",
  "modal error zip empty folder": "Vous ne pouvez pas télécharger un dossier vide en tant que ZIP.",
  "upload running": "Upload en cours. Ne quittez pas votre navigateur.",
  "modal are you sure": "Êtes-vous sûr(e) ?",
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
  "tooltip tag": "Etiquette",
  "file edit save": "Sauvegarder",
  "file edit cancel": "Annuler",
  'and x files': "et un autre fichier ||||\net %{smart_count} autres fichiers",
  "already exists": "existent déjà.",
  "failed to upload": "n'a pas pu être envoyé au serveur |||| n'ont pas pu être envoyés au serveur",
  "upload complete": "Le fichier a été transféré. ||||\n%{smart_count} fichiers ont été transférés.",
  "chrome error dragdrop title": "Des fichiers vont être ignorés",
  "chrome error dragdrop content": "À cause d'un bug de Chrome, les fichiers suivants : %{files} seront\nignorés car leur nom contient un accent. Ajoutez-les en cliquant sur\nle bouton en haut à droite de votre écran. ||||\nÀ cause d'un bug de Chrome, le fichier suivant : %{files} sera\nignoré car son nom contient un accent. Ajoutez-le en cliquant sur\nle bouton en haut à droite de votre écran.",
  "chrome error submit": "Ok",
  "upload caption": "Ajouter des fichiers",
  "upload msg": "Faites glisser des fichiers ou cliquez ici pour sélectionner des fichiers à mettre en ligne.",
  "upload msg selected": "Vous avez sélectionné %{smart_count} fichier, cliquez sur \"Ajouter\" pour les mettre en ligne. ||||\nVous avez sélectionné %{smart_count} fichiers, cliquez sur \"Ajouter\" pour les mettre en ligne.",
  "upload close": "Annuler",
  "upload send": "Ajouter",
  "upload button": "Ajouter un fichier",
  "upload success": "Ajouté avec succès !",
  "upload end button": "Fermer",
  "total progress": "Progression totale",
  "new folder caption": "Créer un nouveau dossier",
  "new folder msg": "Entrer le nom du dossier :",
  "new folder close": "Annuler",
  "new folder send": "Créer",
  "new folder button": "Créer un nouveau dossier",
  "new folder": "nouveau dossier",
  "download all": "Télécharger la sélection",
  "move all": "Déplacer la sélection",
  "remove all": "Supprimer la sélection",
  "drop message": "Déposez ici vos fichiers pour les ajouter",
  "upload folder msg": "Mettre en ligne un dossier",
  "upload folder separator": "ou",
  "overwrite modal title": "Un fichier existe déjà",
  "overwrite modal content": "Voulez-vous écraser \"%{fileName}\" ?",
  "overwrite modal remember label": "Appliquer cette décision à tous les conflits",
  "overwrite modal yes button": "Écraser",
  "overwrite modal no button": "Ignorer",
  "folder": "Dossier",
  "image": "Image",
  "document": "Document",
  "music": "Musique",
  "video": "Vidéo",
  "yes": "Oui",
  "no": "Non",
  "ok": "Ok",
  "name": "Nom",
  "type": "Type",
  "size": "Taille",
  "date": "Dernière modification",
  "download": "Télécharger tous les fichiers",
  "MB": "Mo",
  "KB": "Ko",
  "B": "o",
  "files": "fichiers",
  "element": "%{smart_count} élément |||| %{smart_count} éléments",
  "no file in folder": "Ce dossier est vide.",
  "enable notifications": "Activer les notifications",
  "disable notifications": "Désactiver les notifications",
  "notifications enabled": "Notifications activées",
  "notifications disabled": "Notifications désactivées",
  "open folder": "Ouvrir le dossier",
  "download file": "Consulter le fichier",
  "also have access": "Ces personnes ont également accès, car elles ont accès à un dossier parent",
  "cancel": "Annuler",
  "copy paste link": "Pour donner accès à votre contact envoyez-lui ce lien : ",
  "details": "Détails",
  "inherited from": "hérité de",
  "modal question folder shareable": "Choisissez le mode de partage pour ce dossier",
  "modal shared folder custom msg": "Entrez un email et appuyez sur Entrée",
  "modal shared folder link msg": "Envoyez ce lien pour qu'elles puissent accéder à ce dossier",
  "modal question file shareable": "Choisissez le mode de partage pour ce fichier",
  "modal shared file custom msg": "Entrez un email et appuyez sur Entrée",
  "modal shared file link msg": "Envoyez ce lien pour qu'elles puissent accéder à ce dossier",
  "modal shared public link msg": "Envoyez ce lien pour partager ce dossier ou fichier:",
  "modal shared with people msg": "Invitez une sélection de contacts à y accéder. Saisissez l'email dans le champ et appuyez sur entrée (un email pour les prévenir leur sera envoyé) :",
  "only you can see": "Vous seul(e) pouvez accéder à cette ressource.",
  "public": "Public",
  "private": "Privé",
  "shared": "Partagé",
  "share": "Partager",
  "save": "Sauvegarder",
  "see link": "Voir le lien",
  "sharing": "Partage",
  "revoke": "Révoquer la permission",
  "send mails question": "Envoyer un email de notification à : ",
  "modal send mails": "Envoyer une notification",
  "forced public": "Ce dossier/fichier est partagé car un de ses dossiers parents est partagé.",
  "forced shared": "Ce dossier/fichier est partagé car un de ses dossiers parents est partagé. Voici la liste des personnes avec lesquelles il est partagé :",
  "confirm": "Confirmer",
  "share forgot add": "Il semble que vous ayez oublié d'appuyer sur le bouton Add",
  "share confirm save": "Les changements effectués sur les permissions ne seront pas sauvegardés. Êtes-vous sûr(e) ?",
  "yes forgot": "Retour",
  "no forgot": "Ok",
  "perm": "peut ",
  "perm r file": "consulter ce fichier",
  "perm r folder": "parcourir ce dossier",
  "perm rw folder": "parcourir ce dossier et ajouter des fichiers",
  "change notif": "Cocher cette case pour recevoir une notification cozy quand un contact\najoute un fichier à ce dossier.",
  "send email hint": "Des emails de notification seront envoyés lors de la première sauvegarde.",
  "move": "Déplacer",
  'tooltip move': "Déplacer l'élément dans un autre dossier.",
  "moving...": "Déplacement en cours…",
  "move element to": "Déplacer l'élément vers ",
  "error occured canceling move": "Une erreur est survenue en annulant le déplacement.",
  "error occured while moving element": "Une erreur est survenue en déplaçant l'élément.",
  "file successfully moved to": 'Fichier déplacé avec succès vers ',
  'plugin modal close': 'Fermer',
  'moving selected elements': 'Déplacer des éléments',
  'move elements to': "Déplacer les éléments vers ",
  "elements successfully moved to": 'Eléments déplacés avec succès vers ',
  'close': 'Fermer'
};
});

;require.register("locales/ro", function(exports, require, module) {
module.exports = {
  "modal error": "Eroare",
  "modal ok": "OK",
  "modal error get files": "A apărut o eroare în transferul de fișiere de la server",
  "modal error get folders": "A apărut o eroare în transferul de directoare de la server",
  "modal error get content": "An error occurred while retrieving content of folder \"%{folderName}\" from the server",
  "modal error empty name": "Numele nu poate fi vid",
  "modal error file invalid": "Fișierul nu pare a fi valid",
  "root folder name": "root",
  "confirmation reload": "An operation is in progress, are you sure you want to reload the page?",
  "breadcrumbs search title": "Căutare",
  "modal error file exists": "Ne pare rău, există deja un document cu acest nume",
  "modal error file upload": "Fișierul nu a putut fi trimis server-ului",
  "modal error folder create": "Directorul nu a putut fi creat",
  "modal error folder exists": "Ne pare rău, există deja un director cu acest nume",
  "modal error zip empty folder": "You can't download an empty folder as a ZIP.",
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
  'and x files': "și un alt fișier ||||\nși %{smart_count} alte fișiere",
  "already exists": "există deja.",
  "failed to upload": "nu au putut fi trimise la server.",
  "upload complete": "dosarul a fost trimis cu succes la server ||||\n%{smart_count} dosare au fost trimise cu succes la server.",
  "chrome error dragdrop title": "Files are going to be ignored",
  "chrome error dragdrop content": "Due to a bug in Chrome, the following file: %{files} is going to be\nignored because it has an accent in its name. You can still add\nit by using the button on the top right of your screen. ||||\nDue to a bug in Chrome, the following files: %{files} are going to be\nignored because they have an accent in their name. You can still add\nthem by using the button on the top right of your screen.",
  "chrome error submit": "Ok",
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
  "overwrite modal title": "A file already exist",
  "overwrite modal content": "Do you want to overwrite \"%{fileName}\"?",
  "overwrite modal remember label": "Apply this decision to all conflicts",
  "overwrite modal yes button": "Overwrite",
  "overwrite modal no button": "Skip",
  "folder": "Director",
  "image": "Imagine",
  "document": "Document",
  "music": "Muzică",
  "video": "Video",
  "yes": "Da",
  "no": "Nu",
  "ok": "Ok",
  "name": "Nume",
  "type": "Tip",
  "size": "Dimensiune",
  "date": "Ultima modificare",
  "download": "Descărcare",
  "MB": "Mo",
  "KB": "Ko",
  "B": "o",
  "enable notifications": "Activare notificări",
  "disable notifications": "Dezactivare notificări",
  "open folder": "Accesare director",
  "download file": "Descărcare fișier",
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
  "shared": "Partajat",
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
  "change notif": "Bifați această casetă pentru a fi notificat atunci când o persoană de contact\nadăuga un fișier în acest dosar.",
  "send email hint": "Notification emails will be sent one time on save"
};
});

;require.register("models/file", function(exports, require, module) {
var File, client,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

client = require('../lib/client');

module.exports = File = (function(_super) {
  __extends(File, _super);

  File.prototype.breadcrumb = [];

  function File(options) {
    var doctype, _ref;
    doctype = (_ref = options.docType) != null ? _ref.toLowerCase() : void 0;
    if (doctype != null) {
      options.type = doctype === 'file' ? 'file' : 'folder';
    }
    File.__super__.constructor.call(this, options);
  }

  File.prototype.isFolder = function() {
    return this.get('type') === 'folder';
  };

  File.prototype.isFile = function() {
    return this.get('type') === 'file';
  };

  File.prototype.isSearch = function() {
    return this.get('type') === 'search';
  };

  File.prototype.isRoot = function() {
    return this.get('id') === 'root';
  };

  File.prototype.isBeingUploaded = function() {
    return this.isFile() && (this.file != null) && !this.isUploaded;
  };

  File.prototype.parse = function(data) {
    delete data.success;
    return data;
  };

  File.prototype.getRepository = function() {
    if (this.isRoot()) {
      return "";
    } else {
      return "" + (this.get("path")) + "/" + (this.get("name"));
    }
  };

  File.prototype.sync = function(method, model, options) {
    var formdata, progress;
    if (model.file) {
      formdata = new FormData();
      formdata.append('name', model.get('name'));
      formdata.append('path', model.get('path'));
      formdata.append('lastModification', model.get('lastModification'));
      if (this.overwrite) {
        formdata.append('overwrite', true);
      }
      formdata.append('file', model.file);
      progress = function(e) {
        model.loaded = e.loaded;
        return model.trigger('progress', e);
      };
      _.extend(options, {
        contentType: false,
        data: formdata,
        xhr: function() {
          var xhr;
          xhr = $.ajaxSettings.xhr();
          if (xhr.upload) {
            xhr.upload.addEventListener('progress', progress, false);
          }
          return xhr;
        }
      });
    }
    return Backbone.sync.apply(this, arguments);
  };

  File.prototype.urlRoot = function() {
    var prefix;
    prefix = app.isPublic ? '../' : '';
    if (this.isFolder()) {
      return prefix + 'folders/';
    } else if (this.isSearch()) {
      return prefix + 'search/';
    } else {
      return prefix + 'files/';
    }
  };

  File.prototype.url = function(toAppend) {
    var key, url;
    if (toAppend == null) {
      toAppend = '';
    }
    url = File.__super__.url.call(this);
    key = app.isPublic ? window.location.search : '';
    return url + toAppend + key;
  };

  File.prototype.getPublicURL = function(key) {
    var link, name;
    link = "" + window.location.origin + "/public/files/" + (this.urlRoot()) + this.id;
    if (this.isFile()) {
      name = encodeURIComponent(this.get('name'));
      link = "" + link + "/attach/" + name;
    }
    return link;
  };

  File.prototype.getZipURL = function() {
    var toAppend;
    if (this.isFolder()) {
      toAppend = "/zip/" + (encodeURIComponent(this.get('name')));
      return this.url(toAppend);
    }
  };

  File.prototype.getAttachmentUrl = function() {
    var toAppend;
    if (this.isBeingUploaded()) {
      return "#";
    } else if (this.isFile()) {
      toAppend = "/attach/" + (encodeURIComponent(this.get('name')));
      return this.url(toAppend);
    }
  };

  File.prototype.getDownloadUrl = function() {
    var toAppend;
    if (this.isFile()) {
      toAppend = "/download/" + (encodeURIComponent(this.get('name')));
      return this.url(toAppend);
    } else if (this.isFolder()) {
      return this.getZipURL();
    }
  };

  File.prototype.validate = function(attrs) {
    var errors;
    errors = [];
    if (!attrs.name || attrs.name === '') {
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


  /*
      ONLY RELEVANT IF IT'S A FOLDER
      Fetches content (folders and files) for the current folder
      the request also responds with the breadcrumb
   */

  File.prototype.fetchContent = function(callbacks) {
    var key, url;
    this.prepareCallbacks(callbacks);
    url = "" + (this.urlRoot()) + "content";
    key = window.location.search;
    if (app.isPublic && !this.isSearch()) {
      url = "" + (this.urlRoot()) + this.id + "/content" + key;
    } else if (this.isSearch()) {
      url += key;
    }
    return client.post(url, {
      id: this.id
    }, (function(_this) {
      return function(err, body) {
        var content, parents;
        if (err != null) {
          _this.setBreadcrumb([]);
          return callbacks(err);
        } else {
          if (body.parents != null) {
            content = body.content, parents = body.parents;
          } else {
            content = body;
            parents = [];
          }
          _this.setBreadcrumb(parents || []);
          return callbacks(null, content, parents);
        }
      };
    })(this));
  };

  File.prototype.setBreadcrumb = function(parents) {
    if (this.get('type') === 'search') {
      return this.breadcrumb = [window.app.root.toJSON(), this.toJSON()];
    } else {
      parents.unshift(window.app.root.toJSON());
      if (!this.isRoot()) {
        parents.push(this.toJSON());
      }
      return this.breadcrumb = parents;
    }
  };

  File.prototype.getClearance = function() {
    var inheritedClearance;
    if (app.isPublic) {
      return null;
    } else {
      inheritedClearance = this.get('inheritedClearance');
      if (!inheritedClearance || inheritedClearance.length === 0) {
        return this.get('clearance');
      } else {
        return inheritedClearance[0].clearance;
      }
    }
  };

  return File;

})(Backbone.Model);
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
    if (this.folderView != null) {
      this.folderView.spin();
    }
    return folder.fetchContent((function(_this) {
      return function(err, content) {
        var collection;
        collection = new FileCollection(content);
        if (_this.folderView != null) {
          _this.folderView.spin(false);
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

;require.register("utils/plugin_utils", function(exports, require, module) {
var helpers,
  __hasProp = {}.hasOwnProperty;

helpers = {
  modal: function(options) {
    var win;
    win = document.createElement('div');
    win.classList.add('modal');
    win.classList.add('fade');
    win.innerHTML = "<div class=\"modal-dialog\">\n    <div class=\"modal-content\">\n        <div class=\"modal-header\">\n            <button type=\"button\" class=\"close\" data-dismiss=\"modal\"\n                    aria-label=\"Close\">\n                <span aria-hidden=\"true\">&times;</span>\n            </button>\n            <h4 class=\"modal-title\"></h4>\n        </div>\n        <div class=\"modal-body\"> </div>\n        <div class=\"modal-footer\">\n            <button type=\"button\" class=\"btn btn-default\"\n                    data-dismiss=\"modal\">" + (t('plugin modal close')) + "\n            </button>\n        </div>\n    </div>\n</div>";
    if (options.title) {
      win.querySelector('.modal-title').innerHTML = options.title;
    }
    if (options.body) {
      win.querySelector('.modal-body').innerHTML = options.body;
    }
    if (options.size === 'small') {
      win.querySelector('.modal-dialog').classList.add('modal-sm');
    }
    if (options.size === 'large') {
      win.querySelector('.modal-dialog').classList.add('modal-lg');
    }
    if (options.show !== false) {
      document.body.appendChild(win);
      window.jQuery(win).modal('show');
    }
    return win;
  },
  getFiles: function(extensions, node) {
    var selector;
    selector = extensions.map(function(f) {
      return "[data-file-url$=" + f + "]";
    }).join(',');
    if (node == null) {
      node = document;
    }
    return node.querySelectorAll(selector);
  },
  addIcon: function(elmt, onClick) {
    var icon;
    if (!elmt.dataset.hasPreview) {
      elmt.dataset.hasPreview = true;
      icon = document.createElement('a');
      icon.innerHTML = "<i class='fa fa-eye'></i>";
      icon.addEventListener('click', onClick);
      return elmt.parentNode.querySelector('.operations').appendChild(icon);
    }
  }
};

module.exports = {
  init: function() {
    var config, observer, onMutation, pluginConf, pluginName, _ref;
    if (window.plugins == null) {
      window.plugins = {};
    }
    _ref = window.plugins;
    for (pluginName in _ref) {
      if (!__hasProp.call(_ref, pluginName)) continue;
      pluginConf = _ref[pluginName];
      this.activate(pluginName);
    }
    window.plugins.helpers = helpers;
    if (typeof MutationObserver !== "undefined" && MutationObserver !== null) {
      config = {
        attributes: false,
        childList: true,
        characterData: false,
        subtree: true
      };
      onMutation = function(mutations) {
        var check, checkNode, mutation, _i, _len, _results;
        checkNode = function(node, action) {
          var listener, _ref1, _results;
          if (node.nodeType !== Node.ELEMENT_NODE) {
            return;
          }
          _ref1 = window.plugins;
          _results = [];
          for (pluginName in _ref1) {
            if (!__hasProp.call(_ref1, pluginName)) continue;
            pluginConf = _ref1[pluginName];
            if (pluginConf.active) {
              if (action === 'add') {
                listener = pluginConf.onAdd;
              }
              if (action === 'delete') {
                listener = pluginConf.onDelete;
              }
              if ((listener != null) && listener.condition.bind(pluginConf)(node)) {
                _results.push(listener.action.bind(pluginConf)(node));
              } else {
                _results.push(void 0);
              }
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        };
        check = function(mutation) {
          var node, nodes, _i, _j, _len, _len1, _results;
          nodes = Array.prototype.slice.call(mutation.addedNodes);
          for (_i = 0, _len = nodes.length; _i < _len; _i++) {
            node = nodes[_i];
            checkNode(node, 'add');
          }
          nodes = Array.prototype.slice.call(mutation.removedNodes);
          _results = [];
          for (_j = 0, _len1 = nodes.length; _j < _len1; _j++) {
            node = nodes[_j];
            _results.push(checkNode(node, 'del'));
          }
          return _results;
        };
        _results = [];
        for (_i = 0, _len = mutations.length; _i < _len; _i++) {
          mutation = mutations[_i];
          _results.push(check(mutation));
        }
        return _results;
      };
      observer = new MutationObserver(onMutation);
      return observer.observe(document, config);
    } else {
      return setInterval(function() {
        var _ref1, _results;
        _ref1 = window.plugins;
        _results = [];
        for (pluginName in _ref1) {
          if (!__hasProp.call(_ref1, pluginName)) continue;
          pluginConf = _ref1[pluginName];
          if (pluginConf.active) {
            if (pluginConf.onAdd != null) {
              if (pluginConf.onAdd.condition(document.body)) {
                _results.push(pluginConf.onAdd.action(document.body));
              } else {
                _results.push(void 0);
              }
            } else {
              _results.push(void 0);
            }
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      }, 200);
    }
  },
  activate: function(key) {
    var event, listener, plugin, pluginConf, pluginName, type, _ref, _ref1, _results;
    plugin = window.plugins[key];
    type = plugin.type;
    plugin.active = true;
    if (plugin.listeners != null) {
      _ref = plugin.listeners;
      for (event in _ref) {
        if (!__hasProp.call(_ref, event)) continue;
        listener = _ref[event];
        window.addEventListener(event, listener.bind(plugin));
      }
    }
    if (plugin.onActivate) {
      plugin.onActivate();
    }
    if (type != null) {
      _ref1 = window.plugins;
      _results = [];
      for (pluginName in _ref1) {
        if (!__hasProp.call(_ref1, pluginName)) continue;
        pluginConf = _ref1[pluginName];
        if (pluginName === key) {
          continue;
        }
        if (pluginConf.type === type && pluginConf.active) {
          _results.push(this.deactivate(pluginName));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  },
  deactivate: function(key) {
    var event, listener, plugin, _ref;
    plugin = window.plugins[key];
    plugin.active = false;
    if (plugin.listeners != null) {
      _ref = plugin.listeners;
      for (event in _ref) {
        if (!__hasProp.call(_ref, event)) continue;
        listener = _ref[event];
        window.removeEventListener(event, listener);
      }
    }
    if (plugin.onDeactivate) {
      return plugin.onDeactivate();
    }
  }
};
});

;require.register("views/breadcrumbs", function(exports, require, module) {
var BaseView, BreadcrumbsView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

module.exports = BreadcrumbsView = (function(_super) {
  __extends(BreadcrumbsView, _super);

  function BreadcrumbsView() {
    return BreadcrumbsView.__super__.constructor.apply(this, arguments);
  }

  BreadcrumbsView.prototype.itemview = require('./templates/breadcrumbs_element');

  BreadcrumbsView.prototype.tagName = "ul";

  BreadcrumbsView.prototype.render = function() {
    var folder, opacity, _i, _len, _ref;
    if (this.collection[0].id !== 'root') {
      this.collection.shift();
    }
    opacity = this.collection.length === 1 ? '0.5' : '1';
    this.$el.css('opacity', opacity);
    this.$el.empty();
    _ref = this.collection;
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

;require.register("views/file", function(exports, require, module) {
var BaseView, FileView, ModalShareView, ModalView, ProgressBar, TagsView, client,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

ModalView = require("./modal");

ModalShareView = null;

TagsView = require("../widgets/tags");

ProgressBar = require('../widgets/progressbar');

client = require("../lib/client");

module.exports = FileView = (function(_super) {
  __extends(FileView, _super);

  function FileView() {
    this.onKeyPress = __bind(this.onKeyPress, this);
    this.onMoveClicked = __bind(this.onMoveClicked, this);
    return FileView.__super__.constructor.apply(this, arguments);
  }

  FileView.prototype.className = 'folder-row';

  FileView.prototype.tagName = 'tr';

  FileView.prototype.templateNormal = require('./templates/file');

  FileView.prototype.templateEdit = require('./templates/file_edit');

  FileView.prototype.templateSearch = require('./templates/file_search');

  FileView.prototype.events = {
    'click a.file-tags': 'onTagClicked',
    'click a.file-delete': 'onDeleteClicked',
    'click a.file-share': 'onShareClicked',
    'click a.file-edit': 'onEditClicked',
    'click a.file-edit-save': 'onSaveClicked',
    'click a.file-edit-cancel': 'onCancelClicked',
    'click a.file-move': 'onMoveClicked',
    'keydown input.file-edit-name': 'onKeyPress',
    'change input.selector': 'onSelectChanged'
  };

  FileView.prototype.mimeClasses = {
    'application/octet-stream': 'fa-file-o',
    'application/x-binary': 'fa-file',
    'text/plain': 'fa-file-text-o',
    'text/richtext': 'fa-file-text-o',
    'application/x-rtf': 'fa-file-text-o',
    'application/rtf': 'fa-file-text-o',
    'application/msword': 'fa-file-word-o',
    'application/mspowerpoint': 'fa-file-powerpoint-o',
    'application/vnd.ms-powerpoint': 'fa-file-powerpoint-o',
    'application/x-mspowerpoint': 'fa-file-powerpoint-o',
    'application/excel': 'fa-file-excel-o',
    'application/x-excel': 'fa-file-excel-o',
    'aaplication/vnd.ms-excel': 'fa-file-excel-o',
    'application/x-msexcel': 'fa-file-excel-o',
    'application/pdf': 'fa-file-pdf-o',
    'text/html': 'fa-file-code-o',
    'text/asp': 'fa-file-code-o',
    'text/css': 'fa-file-code-o',
    'application/x-javascript': 'fa-file-code-o',
    'application/x-lisp': 'fa-file-code-o',
    'application/xml': 'fa-file-code-o',
    'text/xml': 'fa-file-code-o',
    'application/x-sh': 'fa-file-code-o',
    'text/x-script.python': 'fa-file-code-o',
    'application/x-bytecode.python': 'fa-file-code-o',
    'text/x-java-source': 'fa-file-code-o',
    'application/postscript': 'fa-image',
    'image/gif': 'fa-image',
    'image/jpg': 'fa-image',
    'image/jpeg': 'fa-image',
    'image/pjpeg': 'fa-image',
    'image/x-pict': 'fa-image',
    'image/pict': 'fa-image',
    'image/png': 'fa-image',
    'image/x-pcx': 'fa-image',
    'image/x-portable-pixmap': 'fa-image',
    'image/x-tiff': 'fa-image',
    'image/tiff': 'fa-image',
    'audio/aiff': 'fa-file-audio-o',
    'audio/x-aiff': 'fa-file-audio-o',
    'audio/midi': 'fa-file-audio-o',
    'audio/x-midi': 'fa-file-audio-o',
    'audio/x-mid': 'fa-file-audio-o',
    'audio/mpeg': 'fa-file-audio-o',
    'audio/x-mpeg': 'fa-file-audio-o',
    'audio/mpeg3': 'fa-file-audio-o',
    'audio/x-mpeg3': 'fa-file-audio-o',
    'audio/wav': 'fa-file-audio-o',
    'audio/x-wav': 'fa-file-audio-o',
    'video/avi': 'fa-file-video-o',
    'video/mpeg': 'fa-file-video-o',
    'application/zip': 'fa-file-archive-o',
    'multipart/x-zip': 'fa-file-archive-o',
    'multipart/x-zip': 'fa-file-archive-o',
    'application/x-bzip': 'fa-file-archive-o',
    'application/x-bzip2': 'fa-file-archive-o',
    'application/x-gzip': 'fa-file-archive-o',
    'application/x-compress': 'fa-file-archive-o',
    'application/x-compressed': 'fa-file-archive-o',
    'application/x-zip-compressed': 'fa-file-archive-o',
    'multipart/x-gzip': 'fa-file-archive-o'
  };

  FileView.prototype.template = function(args) {
    if (this.isSearchMode) {
      return this.templateSearch(args);
    } else {
      return this.templateNormal(args);
    }
  };

  FileView.prototype.getRenderData = function() {
    return _.extend(FileView.__super__.getRenderData.call(this), {
      isBeingUploaded: this.model.isBeingUploaded(),
      attachmentUrl: this.model.getAttachmentUrl(),
      downloadUrl: this.model.getDownloadUrl(),
      clearance: this.model.getClearance()
    });
  };

  FileView.prototype.initialize = function(options) {
    var numUploadChildren, path, uploadQueue;
    this.isSearchMode = options.isSearchMode;
    this.listenTo(this.model, 'change', this.refresh);
    this.listenTo(this.model, 'request', (function(_this) {
      return function() {
        _this.$('.spinholder').show();
        return _this.$('.icon-zone .fa').addClass('hidden');
      };
    })(this));
    this.listenTo(this.model, 'sync error', (function(_this) {
      return function() {
        if (_this.model.conflict) {
          _this.render();
        }
        _this.$('.spinholder').hide();
        return _this.$('.icon-zone .fa').removeClass('hidden');
      };
    })(this));
    this.listenTo(this.model, 'toggle-select', this.onToggleSelect);
    if (!app.isPublic) {
      if (ModalShareView == null) {
        ModalShareView = require("./modal_share");
      }
    }
    if (this.model.isFolder()) {
      uploadQueue = options.uploadQueue;
      path = this.model.getRepository();
      numUploadChildren = uploadQueue.getNumUploadingElementsByPath(path);
      this.hasUploadingChildren = numUploadChildren > 0;
      this.listenTo(uploadQueue, 'add remove reset', (function(_this) {
        return function() {
          var hasItems;
          hasItems = uploadQueue.getNumUploadingElementsByPath(path) > 0;
          return _this.$('.fa-folder').toggleClass('spin', hasItems);
        };
      })(this));
      return this.listenTo(uploadQueue, 'upload-complete', (function(_this) {
        return function() {
          _this.hasUploadingChildren = false;
          return _this.$('.fa-folder').removeClass('spin');
        };
      })(this));
    }
  };

  FileView.prototype.refresh = function() {
    var changes, date;
    changes = Object.keys(this.model.changed);
    if (changes.length === 1) {
      if (changes[0] === 'tags') {
        return;
      }
      if (changes[0] === 'lastModification') {
        date = moment(this.model.changed.lastModification).calendar();
        this.$('td.date-column-cell span').text(date);
        return;
      }
    }
    return this.render();
  };

  FileView.prototype.displayError = function(msg) {
    if (this.errorField == null) {
      this.errorField = $('<span class="error">').insertAfter(this.$('.file-edit-cancel'));
    }
    if (msg === false) {
      return this.errorField.hide();
    } else {
      return this.errorField.text(msg);
    }
  };

  FileView.prototype.onTagClicked = function() {
    return this.tags.toggleInput();
  };

  FileView.prototype.onDeleteClicked = function() {
    return new ModalView(t("modal are you sure"), t("modal delete msg"), t("modal delete ok"), t("modal cancel"), (function(_this) {
      return function(confirm) {
        if (confirm) {
          window.pendingOperations.deletion++;
          return _this.model.destroy({
            success: function() {
              return window.pendingOperations.deletion--;
            },
            error: function() {
              window.pendingOperations.deletion--;
              return ModalView.error(t("modal delete error"));
            }
          });
        }
      };
    })(this));
  };

  FileView.prototype.onEditClicked = function(name) {
    var input, lastIndexOfDot, model, range, width;
    width = this.$(".caption").width() + 10;
    model = this.model.toJSON();
    if (model["class"] == null) {
      model["class"] = 'folder';
    }
    if (typeof name === "string") {
      model.name = name;
    }
    this.$el.html(this.templateEdit({
      model: model,
      clearance: this.model.getClearance()
    }));
    this.$(".file-edit-name").width(width);
    this.$(".file-edit-name").focus();
    lastIndexOfDot = model.name.lastIndexOf('.');
    if (lastIndexOfDot === -1) {
      lastIndexOfDot = model.name.length;
    }
    input = this.$(".file-edit-name")[0];
    console.log(lastIndexOfDot);
    if (typeof input.selectionStart !== "undefined") {
      input.selectionStart = 0;
      input.selectionEnd = lastIndexOfDot;
    } else if (document.selection && document.selection.createRange) {
      input.select();
      range = document.selection.createRange();
      range.collapse(true);
      range.moveStart("character", 0);
      range.moveEnd("character", lastIndexOfDot);
      range.select();
    }
    return this.$el.addClass('edit-mode');
  };

  FileView.prototype.onShareClicked = function() {
    return new ModalShareView({
      model: this.model
    });
  };

  FileView.prototype.onSaveClicked = function() {
    var name;
    name = this.$('.file-edit-name').val();
    if (name && name !== "") {
      this.$el.removeClass('edit-mode');
      this.$('.icon-zone .fa').addClass('hidden');
      this.$('.spinholder').show();
      return this.model.save({
        name: name
      }, {
        wait: true,
        success: (function(_this) {
          return function(data) {
            _this.$('.spinholder').hide();
            _this.$('.icon-zone .fa').removeClass('hidden');
            return _this.render();
          };
        })(this),
        error: (function(_this) {
          return function(model, err) {
            _this.$('.spinholder').hide();
            _this.$('.icon-zone .fa').removeClass('hidden');
            _this.$('.file-edit-name').focus();
            return _this.displayError(err.status === 400 ? t('modal error in use') : t('modal error rename'));
          };
        })(this)
      });
    } else {
      return this.displayError(t("modal error empty name"));
    }
  };

  FileView.prototype.onCancelClicked = function() {
    this.$el.removeClass('edit-mode');
    if (this.model.isNew()) {
      return this.model.destroy();
    } else {
      return this.render();
    }
  };

  FileView.prototype.onMoveClicked = function() {
    var errorTemplate, firstCell, formTemplate, movedTemplate, optionTemplate;
    formTemplate = "<div class=\"move-widget\">\n<span> " + (t('move element to')) + ": </span>\n<select class=\"move-select\"></select>\n<button class=\"button btn move-btn\">\n    " + (t('move')) + "\n</button>\n<button class=\"btn btn-link cancel-move-btn\">\n    " + (t('cancel')) + "\n</button>\n</div>";
    errorTemplate = "<div class=\"move-error\">\n    <span class=\"error\">\n    " + 'modal error file exists' + ": " + (this.model.get('name')) + ".\n    </span>\n</div>";
    movedTemplate = function(path) {
      return "<div id=\"moved-infos\">\n<span>" + (t('file successfully moved to')) + ": /" + path + ".</span>\n<button class=\"btn btn-link cancel-move-btn\">\n    " + (t('cancel')) + "\n</button>\n</div>";
    };
    optionTemplate = function(path) {
      return "<option value=\"" + path + "\">" + path + "</option>";
    };
    firstCell = this.$el.find('td:first-child');
    return client.get('folders/list', (function(_this) {
      return function(err, paths) {
        var cancelButton, fullPath, moveButton, moveForm, parentPath, path, type, _i, _len;
        if (err) {
          return Modal.error(err);
        } else {
          parentPath = _this.model.get('path');
          fullPath = _this.model.getRepository();
          type = _this.model.get('type');
          if (parentPath !== "") {
            paths.push('/');
          }
          moveForm = $(formTemplate);
          for (_i = 0, _len = paths.length; _i < _len; _i++) {
            path = paths[_i];
            if (path !== parentPath && !(type === 'folder' && path.indexOf(fullPath) === 0)) {
              moveForm.find('select').append(optionTemplate(path));
            }
          }
          cancelButton = moveForm.find(".cancel-move-btn");
          cancelButton.click(function() {
            _this.$('.move-error').remove();
            return moveForm.remove();
          });
          moveButton = moveForm.find(".move-btn");
          moveButton.click(function() {
            var id, previousPath, showMoveResult;
            moveButton.html(t("moving..."));
            path = $(".move-select").val().substring(1);
            id = _this.model.get('id');
            previousPath = _this.model.get('path');
            _this.stopListening(_this.model);
            window.app.socket.pause(_this.model, null, {
              ignoreMySocketNotification: true
            });
            showMoveResult = function() {
              var movedInfos;
              moveForm.fadeOut();
              moveForm.remove();
              movedInfos = $(movedTemplate(path));
              firstCell.append(movedInfos);
              cancelButton = movedInfos.find(".cancel-move-btn");
              return movedInfos.click(function() {
                var data;
                data = {
                  path: previousPath
                };
                return client.put("" + type + "s/" + id, data, function(err) {
                  if (err) {
                    return ModalView.error(t('error occured canceling move'));
                  } else {
                    return movedInfos.fadeOut();
                  }
                });
              });
            };
            return client.put("" + type + "s/" + id, {
              path: path
            }, function(err) {
              if (err != null) {
                firstCell.append(errorTemplate);
              } else {
                showMoveResult();
              }
              window.app.socket.resume(_this.model, null, {
                ignoreMySocketNotification: true
              });
              return _this.listenTo(_this.model, 'change', _this.render);
            });
          });
          return _this.$el.find('td:first-child').append(moveForm);
        }
      };
    })(this));
  };

  FileView.prototype.onKeyPress = function(e) {
    if (e.keyCode === 13) {
      return this.onSaveClicked();
    } else if (e.keyCode === 27) {
      return this.render();
    }
  };

  FileView.prototype.onSelectChanged = function(event) {
    var isChecked;
    isChecked = $(event.target).is(':checked');
    this.$el.toggleClass('selected', isChecked);
    this.model.isSelected = isChecked;
    this.onToggleSelect();
    return true;
  };

  FileView.prototype.onToggleSelect = function() {
    this.$el.toggleClass('selected', this.model.isSelected);
    this.$('input.selector').prop('checked', this.model.isSelected);
    if (this.model.isSelected) {
      return this.$('.file-move, .file-delete').addClass('hidden');
    } else {
      return this.$('.file-move, .file-delete').removeClass('hidden');
    }
  };

  FileView.prototype.afterRender = function() {
    var cell;
    if (this.model.isBeingUploaded()) {
      this.$('.type-column-cell').remove();
      this.$('.date-column-cell').remove();
      this.progressbar = new ProgressBar({
        model: this.model
      });
      cell = $('<td colspan="2"></td>');
      cell.append(this.progressbar.render().$el);
      this.$('.size-column-cell').after(cell);
      this.$('a.caption.btn').click(function(event) {
        return event.preventDefault();
      });
    } else {
      this.tags = new TagsView({
        el: this.$('.tags'),
        model: this.model
      });
      this.tags.render();
      this.tags.hideInput();
    }
    if (this.model.isSelected) {
      this.$('.file-move, .file-delete').addClass('hidden');
    } else {
      this.$('.file-move, .file-delete').removeClass('hidden');
    }
    if (this.hasUploadingChildren) {
      this.$('.fa-folder').addClass('spin');
    }
    return this.$('.spinholder').hide();
  };

  return FileView;

})(BaseView);
});

;require.register("views/files", function(exports, require, module) {
var FileView, FilesView, ViewCollection,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

ViewCollection = require('../lib/view_collection');

FileView = require('./file');

module.exports = FilesView = (function(_super) {
  __extends(FilesView, _super);

  function FilesView() {
    return FilesView.__super__.constructor.apply(this, arguments);
  }

  FilesView.prototype.template = require('./templates/files');

  FilesView.prototype.el = '#files';

  FilesView.prototype.itemview = FileView;

  FilesView.prototype.collectionEl = '#table-items-body';

  FilesView.prototype.events = {
    'click #up-name': 'onChangeOrder',
    'click #down-name': 'onChangeOrder',
    'click #up-class': 'onChangeOrder',
    'click #down-class': 'onChangeOrder',
    'click #up-size': 'onChangeOrder',
    'click #down-size': 'onChangeOrder',
    'click #up-lastModification': 'onChangeOrder',
    'click #down-lastModification': 'onChangeOrder'
  };

  FilesView.prototype.initialize = function(options) {
    FilesView.__super__.initialize.call(this, options);
    this.itemViewOptions = function() {
      return {
        isSearchMode: options.isSearchMode,
        uploadQueue: options.uploadQueue
      };
    };
    this.chevron = {
      order: this.collection.order,
      type: this.collection.type
    };
    return this.listenTo(this.collection, 'add remove', this.updateNbFiles);
  };

  FilesView.prototype.afterRender = function() {
    FilesView.__super__.afterRender.call(this);
    this.displayChevron(this.chevron.order, this.chevron.type);
    return this.updateNbFiles();
  };

  FilesView.prototype.updateNbFiles = function() {
    var nbElements;
    nbElements = this.collection.length;
    if (nbElements > 0) {
      this.$("#file-amount-indicator").html(t('element', {
        smart_count: nbElements
      }));
      this.$("#file-amount-indicator").show();
      return this.$("#no-files-indicator").hide();
    } else {
      this.$("#file-amount-indicator").hide();
      return this.$("#no-files-indicator").show();
    }
  };

  FilesView.prototype.displayChevron = function(order, type) {
    if (order === "asc") {
      this.$("#up-" + type).show();
      this.$("#down-" + type).hide();
      return this.$("#up-" + type).removeClass('unactive');
    } else {
      this.$("#up-" + type).hide();
      this.$("#down-" + type).show();
      return this.$("#down-" + type).removeClass('unactive');
    }
  };

  FilesView.prototype.onChangeOrder = function(event) {
    var order, type, _ref;
    _ref = event.target.id.split('-'), order = _ref[0], type = _ref[1];
    order = order === 'up' ? 'desc' : 'asc';
    this.chevron = {
      order: order,
      type: type
    };
    this.collection.order = order;
    this.collection.type = type;
    return this.collection.sort();
  };

  FilesView.prototype.updateInheritedClearance = function(clearance) {
    var file, _i, _len, _ref, _results;
    if ((clearance != null) && clearance.length > 0 && (clearance[0].clearance != null)) {
      _ref = this.collection.models;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        file = _ref[_i];
        _results.push(file.set('inheritedClearance', clearance));
      }
      return _results;
    }
  };

  FilesView.prototype.destroy = function() {
    this.stopListening(this.collection);
    return FilesView.__super__.destroy.call(this);
  };

  return FilesView;

})(ViewCollection);
});

;require.register("views/folder", function(exports, require, module) {
var BACKSPACE_KEY, BaseView, BreadcrumbsView, File, FilesView, FolderView, Modal, ModalBulkMove, ModalConflict, ModalShareView, UploadStatusView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

FilesView = require('./files');

BreadcrumbsView = require("./breadcrumbs");

UploadStatusView = require('./upload_status');

Modal = require('./modal');

ModalBulkMove = require('./modal_bulk_move');

ModalConflict = require('./modal_conflict');

ModalShareView = null;

File = require('../models/file');

BACKSPACE_KEY = 8;


/*
Handles the display logic for a folder.
Main entry point of the interface: handles breadcrumb, buttons and files list
 */

module.exports = FolderView = (function(_super) {
  __extends(FolderView, _super);

  function FolderView() {
    this.onFilesSelected = __bind(this.onFilesSelected, this);
    return FolderView.__super__.constructor.apply(this, arguments);
  }

  FolderView.prototype.el = 'body';

  FolderView.prototype.template = require('./templates/folder');

  FolderView.prototype.events = function() {
    return {
      'click #button-new-folder': 'onNewFolderClicked',
      'click #cancel-new-folder': 'onCancelFolder',
      'click #cancel-new-file': 'onCancelFile',
      'click #share-state': 'onShareClicked',
      'click #download-link': 'onDownloadAsZipClicked',
      'change #uploader': 'onFilesSelected',
      'change #folder-uploader': 'onDirectorySelected',
      'change #select-all': 'onSelectAllChanged',
      'change input.selector': 'onSelectChanged',
      'click #button-bulk-download': 'bulkDownload',
      'click #button-bulk-remove': 'bulkRemove',
      'click #button-bulk-move': 'bulkMove',
      'dragstart #files': 'onDragStart',
      'dragenter #files': 'onDragEnter',
      'dragover #files': 'onDragEnter',
      'dragleave #files': 'onDragLeave',
      'drop #files': 'onDrop',
      'keyup input#search-box': 'onSearchKeyPress'
    };
  };

  FolderView.prototype.initialize = function(options) {
    FolderView.__super__.initialize.call(this, options);
    this.baseCollection = options.baseCollection;
    this.uploadQueue = options.uploadQueue;
    this.query = options.query;
    if (!app.isPublic) {
      if (ModalShareView == null) {
        ModalShareView = require("./modal_share");
      }
    }
    this.listenTo(this.baseCollection, 'toggle-select', this.toggleFolderActions);
    this.listenTo(this.baseCollection, 'remove', this.toggleFolderActions);
    this.listenTo(this.collection, 'remove', this.toggleFolderActions);
    this.listenTo(this.model, 'sync', this.onFolderSync);
    this.conflictQueue = async.queue(this.resolveConflict.bind(this), 1);
    this.conflictRememberedChoice = null;
    this.conflictQueue.drain = (function(_this) {
      return function() {
        return _this.conflictRememberedChoice = null;
      };
    })(this);
    this.listenTo(this.uploadQueue, 'conflict', this.conflictQueue.push);
    return this;
  };

  FolderView.prototype.resolveConflict = function(model, done) {
    if (this.conflictRememberedChoice != null) {
      model.overwrite = this.conflictRememberedChoice;
      model.processSave(model);
      return done();
    } else {
      return new ModalConflict(model, (function(_this) {
        return function(choice, rememberChoice) {
          if (rememberChoice != null) {
            _this.conflictRememberedChoice = rememberChoice;
          }
          model.overwrite = choice;
          model.processSave(model);
          return done();
        };
      })(this));
    }
  };

  FolderView.prototype.destroy = function() {
    this.collection.forEach(function(element) {
      return element.isSelected = false;
    });
    this.breadcrumbsView.destroy();
    this.breadcrumbsView = null;
    this.filesList.destroy();
    this.filesList = null;
    this.conflictQueue.kill();
    this.conflictQueue = null;
    return FolderView.__super__.destroy.call(this);
  };

  FolderView.prototype.getRenderData = function() {
    return {
      supportsDirectoryUpload: this.testEnableDirectoryUpload(),
      model: this.model.toJSON(),
      clearance: this.model.getClearance(),
      query: this.query,
      zipUrl: this.model.getZipURL()
    };
  };

  FolderView.prototype.afterRender = function() {
    this.uploadButton = this.$('#button-upload-new-file');
    this.renderBreadcrumb();
    this.renderFileList();
    this.renderUploadStatus();
    this.refreshData();
    this.$("#loading-indicator").show();
    return this.$('input#search-box').focus();
  };

  FolderView.prototype.renderBreadcrumb = function() {
    this.$('#crumbs').empty();
    this.breadcrumbsView = new BreadcrumbsView({
      collection: this.model.breadcrumb,
      model: this.model
    });
    return this.$("#crumbs").append(this.breadcrumbsView.render().$el);
  };

  FolderView.prototype.renderFileList = function() {
    this.filesList = new FilesView({
      model: this.model,
      collection: this.collection,
      uploadQueue: this.uploadQueue,
      isSearchMode: this.model.get('type') === "search"
    });
    return this.filesList.render();
  };

  FolderView.prototype.renderUploadStatus = function() {
    this.uploadStatus = new UploadStatusView({
      collection: this.uploadQueue
    });
    return this.uploadStatus.render().$el.appendTo(this.$('#upload-status-container'));
  };

  FolderView.prototype.spin = function(state) {
    if (state == null) {
      state = true;
    }
    if (state) {
      return this.$("#loading-indicator").show();
    } else {
      return this.$("#loading-indicator").hide();
    }
  };

  FolderView.prototype.refreshData = function() {
    this.spin();
    return this.baseCollection.getFolderContent(this.model, (function(_this) {
      return function() {
        _this.spin(false);
        return _this.onFolderSync();
      };
    })(this));
  };


  /*
      Button handlers
   */

  FolderView.prototype.onNewFolderClicked = function() {
    var view;
    if (this.newFolder) {
      return this.filesList.views[this.newFolder.cid].$('.file-edit-name').focus();
    } else {
      if (this.newFolder == null) {
        this.newFolder = new File({
          name: '',
          type: 'folder',
          path: this.model.getRepository()
        });
      }
      this.newFolder.type = 'folder';
      this.baseCollection.add(this.newFolder);
      view = this.filesList.views[this.newFolder.cid];
      view.onEditClicked(t("new folder"));
      return this.newFolder.once('sync destroy', (function(_this) {
        return function() {
          return _this.newFolder = null;
        };
      })(this));
    }
  };

  FolderView.prototype.onShareClicked = function() {
    return new ModalShareView({
      model: this.model
    });
  };


  /*
      Drag and Drop and Upload
   */

  FolderView.prototype.onDragStart = function(e) {
    e.preventDefault();
    return e.stopPropagation();
  };

  FolderView.prototype.onDragEnter = function(e) {
    e.preventDefault();
    e.stopPropagation();
    if (!this.isPublic || this.canUpload) {
      this.uploadButton.addClass('btn-cozy-contrast');
      return this.$('#files-drop-zone').show();
    }
  };

  FolderView.prototype.onDragLeave = function(e) {
    e.preventDefault();
    e.stopPropagation();
    if (!this.isPublic || this.canUpload) {
      this.uploadButton.removeClass('btn-cozy-contrast');
      return this.$('#files-drop-zone').hide();
    }
  };

  FolderView.prototype.onDrop = function(e) {
    e.preventDefault();
    e.stopPropagation();
    if (this.isPublic && !this.canUpload) {
      return false;
    }
    if (e.dataTransfer.items != null) {
      this.onFilesSelectedInChrome(e);
    } else {
      this.onFilesSelected(e);
    }
    this.uploadButton.removeClass('btn-cozy-contrast');
    return this.$('#files-drop-zone').hide();
  };

  FolderView.prototype.onDirectorySelected = function(e) {
    var files, input;
    input = this.$('#folder-uploader');
    files = input[0].files;
    if (!files.length) {
      return;
    }
    this.uploadQueue.addFolderBlobs(files, this.model);
    return input.replaceWith(input.clone(true));
  };

  FolderView.prototype.onFilesSelected = function(e) {
    var files, target, _ref;
    files = ((_ref = e.dataTransfer) != null ? _ref.files : void 0) || e.target.files;
    if (!files.length) {
      return;
    }
    this.uploadQueue.addBlobs(files, this.model);
    if (e.target != null) {
      target = $(e.target);
      return target.replaceWith(target.clone(true));
    }
  };

  FolderView.prototype.onFilesSelectedInChrome = function(e) {
    var callback, entry, errors, files, item, items, parseEntriesRecursively, pending, _i, _len, _results;
    items = e.dataTransfer.items;
    if (!items.length) {
      return;
    }
    pending = 0;
    files = [];
    errors = [];
    callback = (function(_this) {
      return function() {
        var formattedErrors, localeOptions, processUpload;
        processUpload = function() {
          var target;
          _this.uploadQueue.addFolderBlobs(files, _this.model);
          if (e.target != null) {
            target = $(e.target);
            return target.replaceWith(target.clone(true));
          }
        };
        if (errors.length > 0) {
          formattedErrors = errors.map(function(name) {
            return "\"" + name + "\"";
          }).join(', ');
          localeOptions = {
            files: formattedErrors,
            smart_count: errors.length
          };
          return new Modal(t('chrome error dragdrop title'), t('chrome error dragdrop content', localeOptions), t('chrome error submit'), null, function(confirm) {
            return processUpload();
          });
        } else {
          return processUpload();
        }
      };
    })(this);
    parseEntriesRecursively = (function(_this) {
      return function(entry, path) {
        var reader;
        pending = pending + 1;
        path = path || "";
        if (path.length > 0) {
          path = "" + path + "/";
        }
        if (entry.isFile) {
          return entry.file(function(file) {
            file.relativePath = "" + path + file.name;
            files.push(file);
            pending = pending - 1;
            if (pending === 0) {
              return callback();
            }
          }, function(error) {
            errors.push(entry.name);
            pending = pending - 1;
            if (pending === 0) {
              return callback();
            }
          });
        } else if (entry.isDirectory) {
          reader = entry.createReader();
          return reader.readEntries(function(entries) {
            var subEntry, _i, _len;
            for (_i = 0, _len = entries.length; _i < _len; _i++) {
              subEntry = entries[_i];
              parseEntriesRecursively(subEntry, "" + path + entry.name);
            }
            return pending = pending - 1;
          });
        }
      };
    })(this);
    _results = [];
    for (_i = 0, _len = items.length; _i < _len; _i++) {
      item = items[_i];
      entry = item.webkitGetAsEntry();
      _results.push(parseEntriesRecursively(entry));
    }
    return _results;
  };


  /*
      Search
   */

  FolderView.prototype.onSearchKeyPress = function(e) {
    var searching;
    if (this.searching !== true) {
      searching = true;
      return setTimeout((function(_this) {
        return function() {
          var query, route;
          query = _this.$('input#search-box').val().trim();
          if (query !== '') {
            route = "#search/" + query;
          } else if (e.keyCode === BACKSPACE_KEY) {
            route = '';
          } else {
            route = null;
          }
          if (route != null) {
            window.app.router.navigate(route, true);
          }
          return searching = false;
        };
      })(this), 1000);
    }
  };

  FolderView.prototype.updateSearch = function(model, collection) {
    this.stopListening(this.model);
    this.stopListening(this.collection);
    this.model = model;
    this.collection = collection;
    $('#upload-buttons').hide();
    if (this.filesList != null) {
      this.filesList.destroy();
      this.$('#loading-indicator').after($('<div id="files"></div>'));
    }
    this.renderBreadcrumb();
    return this.renderFileList();
  };


  /*
      Select elements management
   */

  FolderView.prototype.onSelectAllChanged = function(event) {
    var isChecked;
    isChecked = $(event.target).is(':checked');
    this.$('input.selector').prop('checked', isChecked);
    this.collection.forEach(function(element) {
      element.isSelected = isChecked;
      return element.trigger('toggle-select');
    });
    return this.toggleFolderActions(isChecked);
  };

  FolderView.prototype.onSelectChanged = function() {
    return this.toggleFolderActions();
  };

  FolderView.prototype.getSelectedElements = function() {
    return this.collection.filter(function(element) {
      return element.isSelected;
    });
  };

  FolderView.prototype.toggleFolderActions = function(force) {
    var clearance, selectedElements, shouldChecked, _ref;
    if (force == null) {
      force = false;
    }
    selectedElements = this.getSelectedElements();
    if (selectedElements.length > 0) {
      this.$('#share-state').hide();
      this.$('#upload-btngroup').hide();
      this.$('#button-new-folder').hide();
      this.$('#download-link').hide();
      this.$('#bulk-actions-btngroup').addClass('enabled');
    } else {
      if (app.isPublic) {
        this.$('#download-link').show();
        clearance = (_ref = this.model.getClearance()) != null ? _ref[0] : void 0;
        if ((clearance != null) && clearance.perm === 'rw') {
          this.$('#upload-btngroup').show();
          this.$('#button-new-folder').show();
        }
      } else {
        this.$('#share-state').show();
        this.$('#upload-btngroup').show();
        this.$('#button-new-folder').show();
      }
      this.$('#bulk-actions-btngroup').removeClass('enabled');
    }
    if (force === true) {
      return this.$('input#select-all').prop('checked', true);
    } else if (this.collection.size() === 0) {
      return this.$('input#select-all').prop('checked', false);
    } else {
      shouldChecked = selectedElements.length === this.collection.size();
      return this.$('input#select-all').prop('checked', shouldChecked);
    }
  };


  /*
      Bulk actions management
   */

  FolderView.prototype.bulkRemove = function() {
    return new Modal(t("modal are you sure"), t("modal delete msg"), t("modal delete ok"), t("modal cancel"), (function(_this) {
      return function(confirm) {
        if (confirm) {
          window.pendingOperations.deletion++;
          return async.eachSeries(_this.getSelectedElements(), function(element, cb) {
            return element.destroy({
              success: function() {
                return setTimeout(cb, 200);
              },
              error: function() {
                return setTimeout(cb, 200);
              }
            });
          }, function(err) {
            window.pendingOperations.deletion--;
            if (err != null) {
              Modal.error(t("modal delete error"));
              return console.log(err);
            }
          });
        }
      };
    })(this));
  };

  FolderView.prototype.bulkMove = function() {
    return new ModalBulkMove({
      collection: this.getSelectedElements(),
      parentPath: this.model.getRepository()
    });
  };

  FolderView.prototype.bulkDownload = function() {
    var form, inputValue, selectedElements, selectedPaths, serializedSelection, url;
    selectedElements = this.getSelectedElements();
    selectedPaths = selectedElements.map(function(element) {
      if (element.isFolder()) {
        return "" + (element.getRepository()) + "/";
      } else {
        return "" + (element.getRepository());
      }
    });
    url = this.model.getZipURL();
    serializedSelection = selectedPaths.join(';');
    inputValue = "value=\"" + serializedSelection + "\"";
    form = "<form id=\"temp-zip-download\" action=\"" + url + "\" method=\"post\">\n    <input type=\"hidden\" name=\"selectedPaths\" " + inputValue + "/>\n</form>";
    $('body').append(form);
    $('#temp-zip-download').submit();
    return $('#temp-zip-download').remove();
  };


  /*
      Misc
   */

  FolderView.prototype.testEnableDirectoryUpload = function() {
    var input, supportsDirectoryUpload;
    input = $('<input type="file">')[0];
    supportsDirectoryUpload = (input.directory != null) || (input.mozdirectory != null) || (input.webkitdirectory != null) || (input.msdirectory != null);
    return supportsDirectoryUpload;
  };

  FolderView.prototype.onDownloadAsZipClicked = function(event) {
    if (this.collection.length === 0) {
      event.preventDefault();
      return Modal.error(t('modal error zip empty folder'));
    }
  };

  FolderView.prototype.onFolderSync = function() {
    var clearance, shareStateContent;
    clearance = this.model.getClearance();
    if (clearance === 'public') {
      shareStateContent = "<span class=\"fa fa-globe\"></span>\n<span class=\"text\">" + (t('shared')) + "</span>";
    } else if ((clearance != null) && clearance.length > 0) {
      shareStateContent = "<span class=\"fa fa-globe\"></span>\n<span class=\"text\">" + (t('shared')) + "</span>\n<span>(" + clearance.length + ")</span>";
    } else {
      shareStateContent = "";
    }
    this.$('#folder-state').html(shareStateContent);
    return this.filesList.updateInheritedClearance([
      {
        clearance: clearance
      }
    ]);
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

  ModalView.prototype.id = "dialog-modal";

  ModalView.prototype.className = "modal fade";

  ModalView.prototype.attributes = {
    'tab-index': -1
  };

  ModalView.prototype.template = require('./templates/modal');

  ModalView.prototype.value = 0;

  ModalView.prototype.events = function() {
    return {
      "click #modal-dialog-no": "onNo",
      "click #modal-dialog-yes": "onYes"
    };
  };

  function ModalView(title, msg, yes, no, cb, hideOnYes) {
    this.title = title;
    this.msg = msg;
    this.yes = yes;
    this.no = no;
    this.cb = cb;
    this.hideOnYes = hideOnYes;
    ModalView.__super__.constructor.call(this);
    if (this.hideOnYes == null) {
      this.hideOnYes = true;
    }
  }

  ModalView.prototype.initialize = function() {
    this.$el.on('hidden.bs.modal', this.close.bind(this));
    this.render();
    return this.show();
  };

  ModalView.prototype.onYes = function() {
    if (this.cb) {
      this.cb(true);
    }
    return this.hide();
  };

  ModalView.prototype.onNo = function() {
    if (this.cb) {
      this.cb(false);
    }
    if (this.hideOnYes) {
      return this.hide();
    }
  };

  ModalView.prototype.onShow = function() {};

  ModalView.prototype.close = function() {
    return setTimeout(this.destroy.bind(this), 500);
  };

  ModalView.prototype.show = function() {
    this.$el.modal('show');
    return this.$el.trigger('show');
  };

  ModalView.prototype.hide = function() {
    this.$el.modal('hide');
    return this.$el.trigger('hide');
  };

  ModalView.prototype.render = function() {
    this.$el.append(this.template({
      title: this.title,
      msg: this.msg,
      yes: this.yes,
      no: this.no
    }));
    $("body").append(this.$el);
    this.afterRender();
    return this;
  };

  return ModalView;

})(BaseView);

module.exports.error = function(code, cb) {
  return new ModalView(t("modal error"), code, t("modal ok"), false, cb);
};
});

;require.register("views/modal_bulk_move", function(exports, require, module) {
var Modal, ModalBulkMoveView, client,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Modal = require("./modal");

client = require("../lib/client");

module.exports = ModalBulkMoveView = (function(_super) {
  __extends(ModalBulkMoveView, _super);

  ModalBulkMoveView.prototype.formTemplate = function() {
    return "<div class=\"move-widget\">\n<span> " + (t('move elements to')) + ": </span>\n<select class=\"move-select\"></select>\n</div>";
  };

  ModalBulkMoveView.prototype.movedTemplate = function(path) {
    return "<div id=\"moved-infos\">\n<span>" + (t('elements successfully moved to')) + ": /" + path + ".</span>\n<button class=\"btn btn-link cancel-move-btn\">\n    " + (t('cancel')) + "\n</button>\n</div>";
  };

  ModalBulkMoveView.prototype.optionTemplate = function(path) {
    return "<option value=\"" + path + "\">" + path + "</option>";
  };

  function ModalBulkMoveView(options) {
    ModalBulkMoveView.__super__.constructor.call(this, t('moving selected elements'), '', t('move'), t('close'));
    this.collection = options.collection;
    this.parentPath = options.parentPath;
  }

  ModalBulkMoveView.prototype.afterRender = function() {
    return client.get('folders/list', (function(_this) {
      return function(err, paths) {
        var allowedPaths, forbiddenPaths, path, _i, _len;
        if (err != null) {
          return Modal.error(err);
        } else {
          if (_this.parentPath !== "") {
            paths.push('/');
          }
          forbiddenPaths = _this.collection.filter(function(element) {
            return element.isFolder();
          }).map(function(element) {
            return element.getRepository();
          });
          allowedPaths = _.filter(paths, function(path) {
            var isAllowed, testedPath;
            testedPath = path + '/';
            isAllowed = !_.some(forbiddenPaths, function(forbiddenPath) {
              return testedPath.indexOf(forbiddenPath) === 0;
            });
            return isAllowed && path !== _this.parentPath;
          });
          _this.moveForm = $(_this.formTemplate());
          for (_i = 0, _len = allowedPaths.length; _i < _len; _i++) {
            path = allowedPaths[_i];
            _this.moveForm.find('select').append(_this.optionTemplate(path));
          }
          return _this.$el.find('.modal-body').append(_this.moveForm);
        }
      };
    })(this));
  };

  ModalBulkMoveView.prototype.onYes = function() {
    var newPath, previousPath;
    this.$('#modal-dialog-yes').html(t('moving...'));
    newPath = $('.move-select').val().substring(1);
    previousPath = this.parentPath;
    return this.bulkUpdate(newPath, (function(_this) {
      return function(err) {
        var cancelButton, movedInfos;
        _this.$('#modal-dialog-yes').hide();
        if (err != null) {
          return Modal.error(t('modal error file exists'));
        } else {
          _this.moveForm.fadeOut(function() {
            return _this.moveForm.remove();
          });
          movedInfos = $(_this.movedTemplate(newPath));
          cancelButton = movedInfos.find('.cancel-move-btn');
          cancelButton.click(function() {
            return _this.bulkUpdate(previousPath, function(err) {
              if (err != null) {
                return Modal.error(t('error occured canceling move'));
              } else {
                return _this.onNo();
              }
            });
          });
          return _this.$el.find('.modal-body').append(movedInfos);
        }
      };
    })(this));
  };

  ModalBulkMoveView.prototype.bulkUpdate = function(newPath, callback) {
    window.pendingOperations.move++;
    return async.eachSeries(this.collection, function(model, cb) {
      var id, type;
      id = model.get('id');
      type = model.get('type');
      return client.put("" + type + "s/" + id, {
        path: newPath
      }, cb);
    }, function() {
      window.pendingOperations.move--;
      return callback();
    });
  };

  return ModalBulkMoveView;

})(Modal);
});

;require.register("views/modal_conflict", function(exports, require, module) {
var Modal, ModalConflictView, client,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Modal = require("./modal");

client = require("../lib/client");

module.exports = ModalConflictView = (function(_super) {
  __extends(ModalConflictView, _super);

  ModalConflictView.prototype.conflictTemplate = function() {
    var rememberLabel;
    rememberLabel = t('overwrite modal remember label');
    return "<div class=\"move-widget\">\n<p>" + (t('overwrite modal content', {
      fileName: this.model.get('name')
    })) + "</p>\n<p>\n    <label for=\"rememberChoice\">" + rememberLabel + "</label>\n    <input id=\"rememberChoice\" type=\"checkbox\"/>\n</p>\n</div>";
  };

  function ModalConflictView(model, callback) {
    this.model = model;
    this.callback = callback;
    ModalConflictView.__super__.constructor.call(this, t('overwrite modal title'), '', t('overwrite modal yes button'), t('overwrite modal no button'), this.confirmCallback);
  }

  ModalConflictView.prototype.confirmCallback = function(confirm) {
    var rememberChoice, rememberedChoice;
    rememberChoice = this.$('#rememberChoice').prop('checked');
    if (rememberChoice) {
      rememberedChoice = confirm;
    }
    return this.callback(confirm, rememberedChoice);
  };

  ModalConflictView.prototype.afterRender = function() {
    this.conflictForm = $(this.conflictTemplate());
    return this.$el.find('.modal-body').append(this.conflictForm);
  };

  return ModalConflictView;

})(Modal);
});

;require.register("views/modal_share", function(exports, require, module) {
var BaseView, CozyClearanceModal, Modal, ModalShareView, client,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

BaseView = require('../lib/base_view');

Modal = require("./modal");

client = require("../lib/client");

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
    return client.get("clearance/" + this.model.id, (function(_this) {
      return function(err, data) {
        if (err) {
          return Modal.error('server error occured', function() {
            return _this.$el.modal('hide');
          });
        } else {
          _this.inherited = data.inherited;
          _this.forcedShared = _this.inherited.length > 0;
          if (_this.isPrivateClearance()) {
            _this.makePublic();
          }
          return _this.refresh();
        }
      };
    })(this));
  };

  ModalShareView.prototype.permissions = function() {
    if (this.type === 'folder') {
      return {
        'r': 'perm r folder',
        'rw': 'perm rw folder'
      };
    } else {
      return {
        'r': t('perm r file')
      };
    }
  };

  ModalShareView.prototype.typeaheadFilter = function(item) {
    var email;
    email = item.toString().split(';')[0];
    return ModalShareView.__super__.typeaheadFilter.apply(this, arguments) && __indexOf.call(this.summaryemails, email) < 0;
  };

  ModalShareView.prototype.getRenderData = function() {
    var folder, guest, guests, out, _i, _j, _len, _len1, _ref, _ref1;
    out = ModalShareView.__super__.getRenderData.apply(this, arguments);
    if (this.forcedShared) {
      if (this.inherited != null) {
        if (this.inherited[0].clearance === 'public') {
          out.clearance = 'public';
        } else {
          guests = [];
          _ref = this.inherited;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            folder = _ref[_i];
            _ref1 = folder.clearance;
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              guest = _ref1[_j];
              guests.push(guest);
            }
          }
          out.clearance = this.getClearanceWithContacts(guests);
        }
      }
    }
    return out;
  };

  ModalShareView.prototype.makePrivate = function() {
    if (this.forcedShared) {
      return;
    }
    return ModalShareView.__super__.makePrivate.apply(this, arguments);
  };

  ModalShareView.prototype.afterRender = function() {
    var checkbox, folder, guestCanWrite, html, item, label, list, listitems, rule, summary, text, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
    ModalShareView.__super__.afterRender.apply(this, arguments);
    if (this.forcedShared) {
      this.$('#share-public').addClass('toggled');
      this.$('#select-mode-section').hide();
      if (this.inherited[0].clearance === 'public') {
        text = t('forced public');
        this.$('#select-mode-section').after($('<p>').text(text));
        $('#share-input').hide();
        $('#add-contact').hide();
        $('.input-group').prev('p').hide();
        $('#public-url').removeClass('disabled');
        setTimeout(function() {
          return $('#public-url').focus().select();
        }, 200);
      } else {
        text = t('forced shared');
        this.$('#select-mode-section').after($('<p>').text(text));
        $('#share-input').hide();
        $('#add-contact').hide();
        $('.input-group').prev('p').hide();
        $('.input-group').prev('p').prev('p').hide();
        $('#public-url').prev('p').hide();
        $('#public-url').prev('p').prev('p').hide();
        $('#public-url').hide();
        $('.revoke').hide();
        $('.changeperm').prop('disabled', true);
      }
      $('#modal-dialog-no').hide();
      $('#modal-dialog-yes').html(t('ok'));
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
          if (!folder.clearance) {
            continue;
          }
          summary.push(rule.email);
          listitems.push($('<li>').text(rule.email));
        }
      }
      if (summary.length !== 0) {
        this.summaryemails = summary;
        text = t('also have access') + ': ' + summary.join(', ') + '. ';
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

  ModalShareView.prototype.onYes = function() {
    if (this.forcedShared) {
      return this.close();
    } else {
      return ModalShareView.__super__.onYes.call(this);
    }
  };

  ModalShareView.prototype.onNo = function() {
    if (this.forcedShared) {
      return this.close();
    } else {
      return ModalShareView.__super__.onNo.call(this);
    }
  };

  return ModalShareView;

})(CozyClearanceModal);
});

;require.register("views/public_folder", function(exports, require, module) {
var FolderView, PublicFolderView, client,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

FolderView = require('./folder');

client = require('../lib/client');

module.exports = PublicFolderView = (function(_super) {
  __extends(PublicFolderView, _super);

  function PublicFolderView() {
    return PublicFolderView.__super__.constructor.apply(this, arguments);
  }

  PublicFolderView.prototype.events = function() {
    return _.extend(PublicFolderView.__super__.events.apply(this, arguments), {
      'click #notifications': 'onToggleNotificationClicked'
    });
  };

  PublicFolderView.prototype.initialize = function(options) {
    PublicFolderView.__super__.initialize.call(this, options);
    return this.rootFolder = options.rootFolder;
  };

  PublicFolderView.prototype.afterRender = function() {
    var classes;
    PublicFolderView.__super__.afterRender.call(this);
    classes = ' public';
    if (this.rootFolder.canUpload) {
      classes += ' can-upload';
    }
    return this.$el.addClass(classes);
  };

  PublicFolderView.prototype.getRenderData = function() {
    return _.extend(PublicFolderView.__super__.getRenderData.call(this), {
      isPublic: true,
      areNotificationsEnabled: this.rootFolder.publicNotificationsEnabled,
      hasPublicKey: this.rootFolder.publicKey.length > 0
    });
  };

  PublicFolderView.prototype.onToggleNotificationClicked = function() {
    var key, url;
    key = window.location.search;
    url = "" + (this.model.urlRoot()) + this.rootFolder.id + "/notifications" + key;
    if (this.rootFolder.publicNotificationsEnabled) {
      this.rootFolder.publicNotificationsEnabled = false;
      this.$('#notifications').html('&nbsp;');
      this.$('#notifications').spin('tiny');
      return client.put(url, {
        notificationsState: false
      }, (function(_this) {
        return function(err) {
          _this.$('#notifications').spin(false);
          if (err == null) {
            _this.$('#notifications').html(t('notifications disabled'));
            return _this.$('#notifications').removeClass('toggled');
          }
        };
      })(this));
    } else {
      this.rootFolder.publicNotificationsEnabled = true;
      this.$('#notifications').html('&nbsp;');
      this.$('#notifications').spin('tiny');
      return client.put(url, {
        notificationsState: true
      }, (function(_this) {
        return function(err) {
          _this.$('#notifications').spin(false);
          if (err == null) {
            _this.$('#notifications').html(t('notifications enabled'));
            return _this.$('#notifications').addClass('toggled');
          }
        };
      })(this));
    }
  };

  return PublicFolderView;

})(FolderView);
});

;require.register("views/templates/breadcrumbs_element", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),model = locals_.model;
if ( model.id == "root")
{
buf.push("<li><a href=\"#\"><span class=\"glyphicon glyphicon-home\"></span></a></li>");
}
else
{
if ( model.type == "search")
{
buf.push("<li><a" + (jade.attr("href", "#search/" + (model.id) + "", true, false)) + ">" + (jade.escape((jade_interp = model.name) == null ? '' : jade_interp)) + "</a></li>");
}
else
{
buf.push("<li><a" + (jade.attr("href", "#folders/" + (model.id) + "", true, false)) + ">" + (jade.escape((jade_interp = model.name) == null ? '' : jade_interp)) + "</a></li>");
}
};return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/file", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),model = locals_.model,clearance = locals_.clearance,attachmentUrl = locals_.attachmentUrl,isBeingUploadetag = locals_.isBeingUploadetag,downloadUrl = locals_.downloadUrl,options = locals_.options;
buf.push("<td><!-- empty by default--><div class=\"caption-wrapper\">");
if ( model.type == 'folder')
{
buf.push("<div class=\"caption btn btn-link\"><span class=\"icon-zone\"><div class=\"spinholder\"><img src=\"images/spinner.svg\"/></div><div class=\"selector-wrapper\"><input type=\"checkbox\" class=\"selector\"/></div>");
if ( clearance == 'public')
{
buf.push("<span class=\"fa fa-globe\"></span><i class=\"fa fa-folder-o\"></i>");
}
else if ( clearance && clearance.length > 0)
{
buf.push("<span class=\"fa fa-globe\"></span><i class=\"fa fa-folder-o\"></i>");
}
else
{
buf.push("<i class=\"fa fa-folder\"></i>");
}
buf.push("</span><a" + (jade.attr("href", "#folders/" + (model.id) + "", true, false)) + (jade.attr("title", "" + (t('open folder')) + "", true, false)) + " class=\"btn-link\"><span>" + (jade.escape((jade_interp = model.name) == null ? '' : jade_interp)) + "</span></a></div>");
}
else if ( model.type == 'file')
{
buf.push("<div" + (jade.attr("data-file-url", "" + (attachmentUrl) + "", true, false)) + " class=\"caption btn btn-link\"><span class=\"icon-zone\">");
if ( clearance == 'public')
{
buf.push("<span class=\"fa fa-globe\"></span>");
}
else if ( clearance && clearance.length > 0)
{
buf.push("<span class=\"fa fa-globe\"></span>");
}
buf.push("<div class=\"selector-wrapper\"><input type=\"checkbox\" class=\"selector\"/></div>");
if ( model.mime && this.mimeClasses[model.mime])
{
buf.push("<i" + (jade.cls(["fa " + (this.mimeClasses[model.mime]) + ""], [true])) + "></i>");
}
else
{
buf.push("<i class=\"fa fa-file-o\"></i>");
}
buf.push("</span><a" + (jade.attr("href", "" + (attachmentUrl) + "", true, false)) + (jade.attr("title", "" + (t('download file')) + "", true, false)) + " target=\"_blank\" class=\"btn-link\"><span>" + (jade.escape((jade_interp = model.name) == null ? '' : jade_interp)) + "</span></a></div>");
}
buf.push("<ul class=\"tags\">");
// iterate model.tags || []
;(function(){
  var $$obj = model.tags || [];
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var tag = $$obj[$index];

buf.push("<li class=\"tag\">" + (jade.escape((jade_interp = tag) == null ? '' : jade_interp)) + "<span class=\"deleter\">&times;</span></li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var tag = $$obj[$index];

buf.push("<li class=\"tag\">" + (jade.escape((jade_interp = tag) == null ? '' : jade_interp)) + "<span class=\"deleter\">&times;</span></li>");
    }

  }
}).call(this);

buf.push("</ul>");
if ( !isBeingUploadetag)
{
buf.push("<div class=\"operations\"><a" + (jade.attr("title", "" + (t('tooltip tag')) + "", true, false)) + " class=\"file-tags\"><span class=\"fa fa-tag\"></span></a><a" + (jade.attr("title", "" + (t('tooltip share')) + "", true, false)) + " class=\"file-share\"><span class=\"fa fa-share-alt\"></span></a><a" + (jade.attr("title", "" + (t('tooltip edit')) + "", true, false)) + " class=\"file-edit\"><span class=\"glyphicon glyphicon-edit\"></span></a><a" + (jade.attr("href", "" + (downloadUrl) + "", true, false)) + " target=\"_blank\"" + (jade.attr("title", "" + (t('tooltip download')) + "", true, false)) + " class=\"file-download\"><span class=\"glyphicon glyphicon-cloud-download\"></span></a></div>");
}
buf.push("</div></td><td class=\"size-column-cell\">");
if ( model.type == 'file')
{
options = {base: 2}
buf.push("<span>" + (jade.escape((jade_interp = filesize(model.size || 0, options)) == null ? '' : jade_interp)) + "</span>");
}
buf.push("</td><td class=\"type-column-cell\">");
if ( model.type == 'folder')
{
buf.push("<span class=\"pull-left\">" + (jade.escape((jade_interp = t('folder')) == null ? '' : jade_interp)) + "</span>");
}
else
{
buf.push("<span class=\"pull-left\">" + (jade.escape((jade_interp = t(model.class)) == null ? '' : jade_interp)) + "</span>");
}
buf.push("</td><td class=\"date-column-cell\">");
if ( model.lastModification)
{
buf.push("<span>" + (jade.escape((jade_interp = moment(model.lastModification).calendar()) == null ? '' : jade_interp)) + "</span>");
}
buf.push("</td>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/file_edit", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),model = locals_.model,clearance = locals_.clearance,options = locals_.options;
buf.push("<td><!-- empty by default--><div class=\"caption-wrapper\"><span class=\"caption caption-edit btn btn-link\">");
if ( model.type && model.type == "folder")
{
buf.push("<span class=\"icon-zone\">");
if ( clearance == 'public')
{
buf.push("<span class=\"fa fa-globe\"></span><i class=\"fa fa-folder-o\"></i>");
}
else if ( clearance && clearance.length > 0)
{
buf.push("<span class=\"fa fa-globe\"></span><i class=\"fa fa-folder-o\"></i>");
}
else
{
buf.push("<i class=\"fa fa-folder\"></i>");
}
buf.push("<div class=\"spinholder\"><img src=\"images/spinner.svg\"/></div></span>");
}
else
{
if ( model.mime && this.mimeClasses[model.mime])
{
buf.push("<i" + (jade.cls(["fa " + (this.mimeClasses[model.mime]) + ""], [true])) + "></i>");
}
else
{
buf.push("<i class=\"fa fa-file-o\"></i>");
}
}
buf.push("<input" + (jade.attr("value", model.name, true, false)) + " class=\"caption file-edit-name\"/></span><a class=\"btn btn-sm btn-cozy file-edit-save\">" + (jade.escape((jade_interp = t("file edit save")) == null ? '' : jade_interp)) + "</a><a class=\"btn btn-sm btn-link file-edit-cancel\">" + (jade.escape((jade_interp = t("file edit cancel")) == null ? '' : jade_interp)) + "</a><ul class=\"tags\">");
// iterate model.tags || []
;(function(){
  var $$obj = model.tags || [];
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var tag = $$obj[$index];

buf.push("<li class=\"tag\">" + (jade.escape((jade_interp = tag) == null ? '' : jade_interp)) + "<span class=\"deleter\">&times;</span></li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var tag = $$obj[$index];

buf.push("<li class=\"tag\">" + (jade.escape((jade_interp = tag) == null ? '' : jade_interp)) + "<span class=\"deleter\">&times;</span></li>");
    }

  }
}).call(this);

buf.push("</ul><!-- empty!--></div></td><td class=\"size-column-cell\">");
if ( model.type == 'file')
{
options = {base: 2}
buf.push("<span>" + (jade.escape((jade_interp = filesize(model.size || 0, options)) == null ? '' : jade_interp)) + "</span>");
}
buf.push("</td><td class=\"type-column-cell\">");
if ( model.type == 'folder')
{
buf.push("<span class=\"pull-left\">" + (jade.escape((jade_interp = t('folder')) == null ? '' : jade_interp)) + "</span>");
}
else
{
buf.push("<span class=\"pull-left\">" + (jade.escape((jade_interp = t(model.class)) == null ? '' : jade_interp)) + "</span>");
}
buf.push("</td><td class=\"date-column-cell\">");
if ( model.lastModification)
{
buf.push("<span>" + (jade.escape((jade_interp = moment(model.lastModification).calendar()) == null ? '' : jade_interp)) + "</span>");
}
buf.push("</td>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/file_search", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),model = locals_.model,clearance = locals_.clearance,attachmentUrl = locals_.attachmentUrl,isBeingUploadetag = locals_.isBeingUploadetag,downloadUrl = locals_.downloadUrl,options = locals_.options;
buf.push("<td><p class=\"file-path\">" + (jade.escape((jade_interp = model.path) == null ? '' : jade_interp)) + "/</p><div class=\"caption-wrapper\">");
if ( model.type == 'folder')
{
buf.push("<div class=\"caption btn btn-link\"><span class=\"icon-zone\"><div class=\"spinholder\"><img src=\"images/spinner.svg\"/></div><div class=\"selector-wrapper\"><input type=\"checkbox\" class=\"selector\"/></div>");
if ( clearance == 'public')
{
buf.push("<span class=\"fa fa-globe\"></span><i class=\"fa fa-folder-o\"></i>");
}
else if ( clearance && clearance.length > 0)
{
buf.push("<span class=\"fa fa-globe\"></span><i class=\"fa fa-folder-o\"></i>");
}
else
{
buf.push("<i class=\"fa fa-folder\"></i>");
}
buf.push("</span><a" + (jade.attr("href", "#folders/" + (model.id) + "", true, false)) + (jade.attr("title", "" + (t('open folder')) + "", true, false)) + " class=\"btn-link\"><span>" + (jade.escape((jade_interp = model.name) == null ? '' : jade_interp)) + "</span></a></div>");
}
else if ( model.type == 'file')
{
buf.push("<div" + (jade.attr("data-file-url", "" + (attachmentUrl) + "", true, false)) + " class=\"caption btn btn-link\"><span class=\"icon-zone\">");
if ( clearance == 'public')
{
buf.push("<span class=\"fa fa-globe\"></span>");
}
else if ( clearance && clearance.length > 0)
{
buf.push("<span class=\"fa fa-globe\"></span>");
}
buf.push("<div class=\"selector-wrapper\"><input type=\"checkbox\" class=\"selector\"/></div>");
if ( model.mime && this.mimeClasses[model.mime])
{
buf.push("<i" + (jade.cls(["fa " + (this.mimeClasses[model.mime]) + ""], [true])) + "></i>");
}
else
{
buf.push("<i class=\"fa fa-file-o\"></i>");
}
buf.push("</span><a" + (jade.attr("href", "" + (attachmentUrl) + "", true, false)) + (jade.attr("title", "" + (t('download file')) + "", true, false)) + " target=\"_blank\" class=\"btn-link\"><span>" + (jade.escape((jade_interp = model.name) == null ? '' : jade_interp)) + "</span></a></div>");
}
buf.push("<ul class=\"tags\">");
// iterate model.tags || []
;(function(){
  var $$obj = model.tags || [];
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var tag = $$obj[$index];

buf.push("<li class=\"tag\">" + (jade.escape((jade_interp = tag) == null ? '' : jade_interp)) + "<span class=\"deleter\">&times;</span></li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var tag = $$obj[$index];

buf.push("<li class=\"tag\">" + (jade.escape((jade_interp = tag) == null ? '' : jade_interp)) + "<span class=\"deleter\">&times;</span></li>");
    }

  }
}).call(this);

buf.push("</ul>");
if ( !isBeingUploadetag)
{
buf.push("<div class=\"operations\"><a" + (jade.attr("title", "" + (t('tooltip tag')) + "", true, false)) + " class=\"file-tags\"><span class=\"fa fa-tag\"></span></a><a" + (jade.attr("title", "" + (t('tooltip share')) + "", true, false)) + " class=\"file-share\"><span class=\"fa fa-share-alt\"></span></a><a" + (jade.attr("title", "" + (t('tooltip edit')) + "", true, false)) + " class=\"file-edit\"><span class=\"glyphicon glyphicon-edit\"></span></a><a" + (jade.attr("href", "" + (downloadUrl) + "", true, false)) + " target=\"_blank\"" + (jade.attr("title", "" + (t('tooltip download')) + "", true, false)) + " class=\"file-download\"><span class=\"glyphicon glyphicon-cloud-download\"></span></a></div>");
}
buf.push("</div></td><td class=\"size-column-cell\">");
if ( model.type == 'file')
{
options = {base: 2}
buf.push("<span>" + (jade.escape((jade_interp = filesize(model.size || 0, options)) == null ? '' : jade_interp)) + "</span>");
}
buf.push("</td><td class=\"type-column-cell\">");
if ( model.type == 'folder')
{
buf.push("<span class=\"pull-left\">" + (jade.escape((jade_interp = t('folder')) == null ? '' : jade_interp)) + "</span>");
}
else
{
buf.push("<span class=\"pull-left\">" + (jade.escape((jade_interp = t(model.class)) == null ? '' : jade_interp)) + "</span>");
}
buf.push("</td><td class=\"date-column-cell\">");
if ( model.lastModification)
{
buf.push("<span>" + (jade.escape((jade_interp = moment(model.lastModification).calendar()) == null ? '' : jade_interp)) + "</span>");
}
buf.push("</td>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/files", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),model = locals_.model;
buf.push("<table id=\"table-items\" class=\"table table-hover\"><thead><tr class=\"table-headers\"><td><input id=\"select-all\" type=\"checkbox\"/><span>" + (jade.escape(null == (jade_interp = t('name')) ? "" : jade_interp)) + "</span><a id=\"down-name\" class=\"btn glyphicon glyphicon-chevron-down unactive\"></a><a id=\"up-name\" class=\"btn glyphicon glyphicon-chevron-up unactive\"></a></td><td class=\"size-column-cell\"><span>" + (jade.escape(null == (jade_interp = t('size')) ? "" : jade_interp)) + "</span><a id=\"down-size\" class=\"glyphicon glyphicon-chevron-down btn unactive\"></a><a id=\"up-size\" class=\"unactive btn glyphicon glyphicon-chevron-up unactive\"></a></td><td class=\"type-column-cell\"><span>" + (jade.escape(null == (jade_interp = t('type')) ? "" : jade_interp)) + "</span><a id=\"down-class\" class=\"btn glyphicon glyphicon-chevron-down unactive\"></a><a id=\"up-class\" class=\"glyphicon glyphicon-chevron-up btn unactive\"></a></td><td class=\"date-column-cell\"><span>" + (jade.escape(null == (jade_interp = t('date')) ? "" : jade_interp)) + "</span><a id=\"down-lastModification\" class=\"btn glyphicon glyphicon-chevron-down unactive\"></a><a id=\"up-lastModification\" class=\"btn glyphicon glyphicon-chevron-up unactive\"></a></td></tr></thead><tbody id=\"table-items-body\"></tbody></table><p id=\"file-amount-indicator\" class=\"footer\"></p><p id=\"no-files-indicator\" class=\"footer\">");
if ( model.type == 'search')
{
buf.push("" + (jade.escape((jade_interp = t('no file in search')) == null ? '' : jade_interp)) + "");
}
else
{
buf.push("" + (jade.escape((jade_interp = t('no file in folder')) == null ? '' : jade_interp)) + "");
}
buf.push("</p>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/folder", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),isPublic = locals_.isPublic,hasPublicKey = locals_.hasPublicKey,query = locals_.query,model = locals_.model,clearance = locals_.clearance,supportsDirectoryUpload = locals_.supportsDirectoryUpload,areNotificationsEnabled = locals_.areNotificationsEnabled,zipUrl = locals_.zipUrl;
buf.push("<div id=\"affixbar\" data-spy=\"affix\" data-offset-top=\"1\"><div class=\"container\"><div class=\"row\"><div class=\"col-lg-12\"><div id=\"crumbs\" class=\"pull-left\"></div><div class=\"pull-right\">");
if ( !isPublic || hasPublicKey)
{
buf.push("<input id=\"search-box\" type=\"search\"" + (jade.attr("value", "" + (query) + "", true, false)) + " class=\"pull-right\"/>");
}
if ( model.type != 'search')
{
buf.push("<div id=\"upload-buttons\" class=\"pull-right\">");
if ( model.id != 'root')
{
buf.push("<span id=\"folder-state\">");
if ( clearance == 'public')
{
buf.push("<span class=\"fa fa-globe\"></span><span class=\"text\">" + (jade.escape((jade_interp = t('shared')) == null ? '' : jade_interp)) + "</span>");
}
else if ( clearance && clearance.length > 0)
{
buf.push("<span class=\"fa fa-globe\"></span><span class=\"text\">" + (jade.escape((jade_interp = t('shared')) == null ? '' : jade_interp)) + "</span><span>&nbsp;(" + (jade.escape((jade_interp = clearance.length) == null ? '' : jade_interp)) + ")</span>");
}
buf.push("</span><a" + (jade.attr("title", "" + (t('share')) + "", true, false)) + " id=\"share-state\" class=\"btn btn-cozy btn-cozy-contrast\"><span class=\"fa fa-share-alt\"></span></a>&nbsp;");
}
buf.push("<div id=\"upload-btngroup\" class=\"btn-group\"><a id=\"button-upload-new-file\" class=\"btn btn-cozy btn-cozy\"><input id=\"uploader\" type=\"file\" multiple=\"multiple\"" + (jade.attr("title", t('upload button'), true, false)) + "/><img src=\"images/add-file.png\"/></a>");
if ( supportsDirectoryUpload)
{
buf.push("<a data-toggle=\"dropdown\" class=\"btn btn-cozy dropdown-toggle\"><span class=\"caret\"></span></a><ul class=\"dropdown-menu\"><li><a id=\"button-upload-folder\"><input id=\"folder-uploader\" type=\"file\" directory=\"directory\" mozdirectory=\"mozdirectory\" webkitdirectory=\"webkitdirectory\"/><span>" + (jade.escape(null == (jade_interp = t('upload folder msg')) ? "" : jade_interp)) + "</span></a></li></ul>");
}
buf.push("</div>&nbsp;<a id=\"button-new-folder\"" + (jade.attr("title", t('new folder button'), true, false)) + " class=\"btn btn-cozy\"><img src=\"images/add-folder.png\"/></a><div id=\"bulk-actions-btngroup\" class=\"btn-group\">");
if ( isPublic)
{
buf.push("<a id=\"button-bulk-download\"" + (jade.attr("title", "" + (t('download all')) + "", true, false)) + " class=\"btn btn-cozy-contrast\"><span class=\"label\">" + (jade.escape((jade_interp = t("download all")) == null ? '' : jade_interp)) + "&nbsp;</span><span class=\"icon-arrow-down icon-white\"></span></a>");
}
else
{
buf.push("<a id=\"button-bulk-download\"" + (jade.attr("title", "" + (t('download all')) + "", true, false)) + " class=\"btn btn-cozy\"><span class=\"icon-arrow-down icon-white\"></span></a>");
}
buf.push("<a id=\"button-bulk-move\"" + (jade.attr("title", "" + (t('move all')) + "", true, false)) + " class=\"btn btn-cozy btn-cozy\"><span class=\"glyphicon glyphicon-arrow-right\"></span></a><a id=\"button-bulk-remove\"" + (jade.attr("title", "" + (t('remove all')) + "", true, false)) + " class=\"btn btn-cozy btn-cozy\"><span class=\"glyphicon glyphicon-remove-circle\"></span></a></div></div>");
if ( isPublic && hasPublicKey)
{
if ( areNotificationsEnabled)
{
buf.push("<a id=\"notifications\" class=\"btn btn-cozy toggled\">" + (jade.escape(null == (jade_interp = t('notifications enabled')) ? "" : jade_interp)) + "</a>");
}
else
{
buf.push("<a id=\"notifications\" class=\"btn btn-cozy\">" + (jade.escape(null == (jade_interp = t('notifications disabled')) ? "" : jade_interp)) + "</a>");
}
buf.push("&nbsp;");
}
buf.push("<a id=\"download-link\"" + (jade.attr("href", "" + (zipUrl) + "", true, false)) + (jade.attr("title", t("download"), true, false)) + " class=\"btn btn-cozy-contrast\">" + (jade.escape((jade_interp = t("download")) == null ? '' : jade_interp)) + "&nbsp;<i class=\"icon-arrow-down icon-white\"></i></a>");
}
buf.push("</div></div></div><div class=\"row\"><div id=\"upload-status-container\" class=\"col-lg-12\"></div></div></div></div><div class=\"container\"><div class=\"row\"><div id=\"content\" class=\"col-lg-12\"><div id=\"loading-indicator\"><img src=\"images/spinner.svg\" width=\"20\"/></div><div id=\"files\"></div><div id=\"files-drop-zone\"><div class=\"overlay\"></div><div class=\"vertical-container\"><p>" + (jade.escape(null == (jade_interp = t('drop message')) ? "" : jade_interp)) + "</p></div></div></div></div></div>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/modal", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),title = locals_.title,msg = locals_.msg,no = locals_.no,yes = locals_.yes;
buf.push("<div class=\"modal-dialog\"><div class=\"modal-content\"><div class=\"modal-header\"><button type=\"button\" data-dismiss=\"modal\" aria-hidden=\"true\" class=\"close\">×</button><h4 class=\"modal-title\">" + (jade.escape((jade_interp = title) == null ? '' : jade_interp)) + "</h4></div><div class=\"modal-body\"><p>" + (jade.escape((jade_interp = msg) == null ? '' : jade_interp)) + "</p></div><div class=\"modal-footer\">");
if ( no)
{
buf.push("<button id=\"modal-dialog-no\" type=\"button\" class=\"btn btn-link\">" + (jade.escape((jade_interp = no) == null ? '' : jade_interp)) + "</button>");
}
if ( yes)
{
buf.push("<button id=\"modal-dialog-yes\" type=\"button\" class=\"btn btn-cozy\">" + (jade.escape((jade_interp = yes) == null ? '' : jade_interp)) + "</button>");
}
buf.push("</div></div></div>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/modal_folder", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<div class=\"modal-dialog\"><div class=\"modal-content\"><div class=\"modal-header\"><button type=\"button\" data-dismiss=\"modal\" aria-hidden=\"true\" class=\"close\">×</button><h4 class=\"modal-title\">" + (jade.escape((jade_interp = t("new folder caption")) == null ? '' : jade_interp)) + "</h4></div><div class=\"modal-body\"><fieldset><div class=\"form-group\"><label for=\"inputName\">" + (jade.escape((jade_interp = t("new folder msg")) == null ? '' : jade_interp)) + "</label><input id=\"inputName\" type=\"text\" class=\"form-control\"/></div><div id=\"folder-upload-form\" class=\"form-group hide\"><br/><p class=\"text-center\">" + (jade.escape(null == (jade_interp = t('upload folder separator')) ? "" : jade_interp)) + "</p><label for=\"inputName\">" + (jade.escape((jade_interp = t("upload folder msg")) == null ? '' : jade_interp)) + "</label><input id=\"folder-uploader\" type=\"file\" directory=\"directory\" mozdirectory=\"mozdirectory\" webkitdirectory=\"webkitdirectory\" class=\"form-control\"/></div></fieldset></div><div class=\"modal-footer\"><button id=\"modal-dialog-no\" type=\"button\" data-dismiss=\"modal\" class=\"btn btn-link\">" + (jade.escape((jade_interp = t("new folder close")) == null ? '' : jade_interp)) + "</button><button id=\"modal-dialog-yes\" type=\"button\" disabled=\"disabled\" class=\"btn btn-cozy-contrast\">" + (jade.escape((jade_interp = t("new folder send")) == null ? '' : jade_interp)) + "</button></div></div></div>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/progressbar", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),value = locals_.value;
buf.push("<div class=\"progress active\"><div role=\"progressbar\"" + (jade.attr("aria-valuenow", "" + (value) + "", true, false)) + " aria-valuemin=\"0\" aria-valuemax=\"100\"" + (jade.attr("style", "width: " + (value) + "%", true, false)) + " class=\"progress-bar progress-bar-info\">" + (jade.escape((jade_interp = value) == null ? '' : jade_interp)) + "%</div></div>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/upload_status", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),value = locals_.value;
buf.push("<span>" + (jade.escape(null == (jade_interp = t('upload running')) ? "" : jade_interp)) + "</span><div id=\"dismiss\" class=\"btn btn-cozy pull-right\">" + (jade.escape(null == (jade_interp = t('ok')) ? "" : jade_interp)) + "</div><div class=\"progress active pull-right\"><div" + (jade.attr("style", "width: " + value, true, false)) + " class=\"progress-bar progress-bar-info\"></div><div class=\"progress-bar progress-bar-content\">" + (jade.escape((jade_interp = t('total progress')) == null ? '' : jade_interp)) + " " + (jade.escape((jade_interp = value) == null ? '' : jade_interp)) + "</div></div>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/upload_status", function(exports, require, module) {
var BaseView, File, ProgressBar, UploadStatusView, UploadedFileView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

File = require('../models/file');

ProgressBar = require('../widgets/progressbar');

UploadedFileView = require('./uploaded_file_view');

module.exports = UploadStatusView = (function(_super) {
  __extends(UploadStatusView, _super);

  function UploadStatusView() {
    return UploadStatusView.__super__.constructor.apply(this, arguments);
  }

  UploadStatusView.prototype.id = "upload-status";

  UploadStatusView.prototype.template = require('./templates/upload_status');

  UploadStatusView.prototype.events = function() {
    return {
      'click #dismiss': 'resetCollection'
    };
  };

  UploadStatusView.prototype.initialize = function() {
    UploadStatusView.__super__.initialize.apply(this, arguments);
    this.listenTo(this.collection, 'add', this.uploadCount);
    this.listenTo(this.collection, 'remove', this.uploadCount);
    this.listenTo(this.collection, 'reset', this.render);
    this.listenTo(this.collection, 'upload-progress', this.progress);
    return this.listenTo(this.collection, 'upload-complete', this.complete);
  };

  UploadStatusView.prototype.getRenderData = function() {
    var data, e, value;
    e = this.collection.progress;
    value = e ? parseInt(100 * e.loadedBytes / e.totalBytes) + '%' : '0 %';
    return data = {
      value: value,
      collection: this.collection
    };
  };

  UploadStatusView.prototype.progress = function(e) {
    var percentage;
    this.$el.removeClass('success danger warning');
    percentage = parseInt(100 * e.loadedBytes / e.totalBytes) + '%';
    this.progressbar.width(percentage);
    return this.progressbarContent.text("" + (t('total progress')) + " : " + percentage);
  };

  UploadStatusView.prototype.complete = function() {
    var result;
    this.$('.progress').remove();
    result = this.collection.getResults();
    if (result.success > 0 || result.error > 0 || result.existing > 0) {
      this.dismiss.show();
      this.$el.addClass(result.status);
      return this.$('span').text([
        result.success ? t('upload complete', {
          smart_count: result.success
        }) : void 0, result.existing.length ? this.makeExistingSentence(result.existing) : void 0, result.error.length ? this.makeErrorSentence(result.error) : void 0
      ].join(' '));
    } else {
      return this.resetCollection();
    }
  };

  UploadStatusView.prototype.makeExistingSentence = function(existing) {
    var parts;
    parts = [existing[0].get('name')];
    if (existing.length > 1) {
      parts.push(t('and x files', {
        smart_count: existing.length - 1
      }));
    }
    parts.push(t('already exists'));
    return parts.join(' ');
  };

  UploadStatusView.prototype.makeErrorSentence = function(errors) {
    var error, parts, _i, _len;
    parts = [];
    parts.push("" + (errors.pop().get('name')));
    if (errors.length > 1) {
      parts.push(t('and x files', {
        smart_count: errors.length - 1
      }));
    }
    parts.push(t('failed to upload', {
      smart_count: errors.length - 1
    }));
    if (errors.length > 1) {
      parts.push(': ');
      parts.push("" + (errors.pop().get('name')));
      for (_i = 0, _len = errors.length; _i < _len; _i++) {
        error = errors[_i];
        parts.push(", " + (error.get('name')));
      }
    }
    return parts.join(' ');
  };

  UploadStatusView.prototype.resetCollection = function() {
    return this.collection.reset();
  };

  UploadStatusView.prototype.uploadCount = function(e) {
    if (this.collection.length > 0) {
      this.$el.show();
      $('#content').addClass('mt108');
    }
    if (this.completed && !this.collection.completed) {
      this.render();
    }
    this.counter.text(this.collection.length);
    return this.counterDone.text(this.collection.loaded);
  };

  UploadStatusView.prototype.afterRender = function() {
    this.$el.removeClass('success danger warning');
    this.counter = this.$('.counter');
    this.counterDone = this.$('.counter-done');
    this.progressbar = this.$('.progress-bar-info');
    this.progressbarContent = this.$('.progress-bar-content');
    this.dismiss = this.$('#dismiss').hide();
    if (this.collection.length === 0) {
      this.$el.hide();
      $('#content').removeClass('mt108');
    } else {
      $('#content').addClass('mt108');
    }
    if (this.collection.completed) {
      return this.complete();
    }
  };

  return UploadStatusView;

})(BaseView);
});

;require.register("views/uploaded_file_view", function(exports, require, module) {
var BaseView, ProgressBar, UploadedFileView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

ProgressBar = require('../widgets/progressbar');

BaseView = require('../lib/base_view');

module.exports = UploadedFileView = (function(_super) {
  __extends(UploadedFileView, _super);

  function UploadedFileView() {
    return UploadedFileView.__super__.constructor.apply(this, arguments);
  }

  UploadedFileView.prototype.className = 'upload-progress-item';

  UploadedFileView.prototype.initialize = function(options) {
    UploadedFileView.__super__.initialize.call(this, options);
    this.isDone = false;
    return this.listenTo(this.model, 'sync', (function(_this) {
      return function() {
        _this.isDone = true;
        return _this.render();
      };
    })(this));
  };

  UploadedFileView.prototype.template = function() {
    var content;
    content = $("<div class=\"progress-name\">\n    <span class=\"name\">" + (this.model.get('name')) + "</span>\n</div>");
    if (this.model.error) {
      content.append("<span class=\"error\"> : " + this.model.error + "</span>");
    } else if (this.isDone || this.model.isUploaded) {
      content.append("<span class=\"success\">" + (t('upload success')) + "</span>");
    } else {
      content.append(new ProgressBar({
        model: this.model
      }).render().$el);
    }
    return content;
    return {
      destroy: function() {
        this.stopListening(this.model);
        return UploadedFileView.__super__.template.call(this);
      }
    };
  };

  return UploadedFileView;

})(BaseView);
});

;require.register("widgets/autocomplete", function(exports, require, module) {
var ARROW_DOWN_KEY, ARROW_UP_KEY, Autocomplete, BaseView, ENTER_KEY,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

BaseView = require('../lib/base_view');

ENTER_KEY = 13;

ARROW_UP_KEY = 38;

ARROW_DOWN_KEY = 40;

module.exports = Autocomplete = (function(_super) {
  __extends(Autocomplete, _super);

  function Autocomplete() {
    this.unbind = __bind(this.unbind, this);
    this.delayedUnbind = __bind(this.delayedUnbind, this);
    this.onInputKeyDown = __bind(this.onInputKeyDown, this);
    return Autocomplete.__super__.constructor.apply(this, arguments);
  }

  Autocomplete.prototype.className = 'autocomplete';

  Autocomplete.prototype.tagName = 'ul';

  Autocomplete.prototype.events = function() {
    return {
      'click li': 'onClick'
    };
  };

  Autocomplete.prototype.onInputKeyDown = function(e) {
    var delta, _ref;
    if ((_ref = e.keyCode) === ARROW_UP_KEY || _ref === ARROW_DOWN_KEY) {
      delta = e.keyCode - 39;
      this.select(this.selectedIndex + delta);
      e.preventDefault();
      return e.stopPropagation();
    }
  };

  Autocomplete.prototype.onClick = function(e) {
    var event;
    this.input.val(e.target.dataset.value);
    event = $.Event('keydown');
    event.keyCode = ENTER_KEY;
    this.input.trigger(event);
    e.preventDefault();
    e.stopPropagation();
    this.unbindCancel = true;
    this.input.parents('.folder-row').addClass('pseudohover');
    return this.input.focus();
  };

  Autocomplete.prototype.initialize = function(options) {
    if (options == null) {
      options = {};
    }
    this.limit = options.limit || 10;
    if (window.tags == null) {
      window.tags = [];
    }
    return this.tags = window.tags.map(function(value, idx) {
      var el, lc;
      el = document.createElement('li');
      el.textContent = value;
      el.dataset.value = value;
      el.dataset.index = idx;
      lc = value.toLowerCase();
      return {
        value: value,
        el: el,
        lc: lc
      };
    });
  };

  Autocomplete.prototype.position = function() {
    var pos;
    pos = this.input.offset();
    pos.top += this.input.height() + 2;
    pos.width = this.input.width() + 2;
    return this.$el.appendTo($('body')).css(pos).show();
  };

  Autocomplete.prototype.refresh = function(search, existings) {
    var selected, tag, _i, _len, _ref, _ref1;
    search = this.input.val();
    selected = (_ref = this.visible) != null ? _ref[this.selectedIndex] : void 0;
    if (existings == null) {
      existings = [];
    }
    _ref1 = this.tags;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      tag = _ref1[_i];
      tag.el.classList.remove('selected');
    }
    this.visible = this.tags.filter((function(_this) {
      return function(tag, index) {
        var _ref2;
        return (_ref2 = tag.value, __indexOf.call(existings, _ref2) < 0) && (tag.lc != null) && ~tag.lc.indexOf(search.toLowerCase()) && index < _this.limit;
      };
    })(this));
    if (selected && __indexOf.call(this.visible, selected) >= 0) {
      this.selectedIndex = this.visible.indexOf(selected);
    } else {
      this.selectedIndex = -1;
    }
    this.$el.empty().append(_.pluck(this.visible, 'el'));
    return this.$el.toggleClass('empty', this.visible.length === 0);
  };

  Autocomplete.prototype.select = function(index) {
    var tag, visibleElement, _i, _len, _ref;
    _ref = this.tags;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tag = _ref[_i];
      tag.el.classList.remove('selected');
    }
    index = (index + this.visible.length) % this.visible.length;
    this.selectedIndex = index;
    visibleElement = this.visible[this.selectedIndex];
    if (visibleElement != null) {
      visibleElement.el.classList.add('selected');
      return this.input.val(visibleElement.value);
    }
  };

  Autocomplete.prototype.bind = function($target) {
    if ($target === this.$target) {
      return;
    }
    if (this.$target) {
      this.unbind();
    }
    this.$target = $target;
    this.input = this.$target.find('input');
    this.position();
    this.input.on('keydown', this.onInputKeyDown);
    this.input.on('blur', this.delayedUnbind);
    return this.selectedIndex = -1;
  };

  Autocomplete.prototype.delayedUnbind = function() {
    this.unbindCancel = false;
    if (this.delayedUnbindTimeout) {
      clearTimeout(this.delayedUnbindTimeout);
    }
    return this.delayedUnbindTimeout = setTimeout(this.unbind, 100);
  };

  Autocomplete.prototype.unbind = function() {
    if (this.unbindCancel || !this.input) {
      return;
    }
    this.input.off('keydown', this.onInputKeyDown);
    this.input.off('blur', this.delayedUnbind);
    this.input.parents('.folder-row').removeClass('pseudohover');
    this.input.val('');
    this.$target = null;
    this.$el.hide();
    this.$el.detach();
    return this.selectedIndex = -1;
  };

  return Autocomplete;

})(BaseView);
});

;require.register("widgets/progressbar", function(exports, require, module) {
var BaseView, ProgressbarView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

module.exports = ProgressbarView = (function(_super) {
  __extends(ProgressbarView, _super);

  function ProgressbarView() {
    return ProgressbarView.__super__.constructor.apply(this, arguments);
  }

  ProgressbarView.prototype.className = 'progressview';

  ProgressbarView.prototype.template = require('../views/templates/progressbar');

  ProgressbarView.prototype.value = 0;

  ProgressbarView.prototype.initialize = function() {
    this.listenTo(this.model, 'progress', this.update);
    this.listenTo(this.model, 'sync', this.destroy);
    return this.value = this.getProgression(this.model.loaded, this.model.total);
  };

  ProgressbarView.prototype.update = function(e) {
    this.value = this.getProgression(e.loaded, e.total);
    return this.$('.progress-bar').text(this.value + '%').width(this.value + '%');
  };

  ProgressbarView.prototype.getProgression = function(loaded, total) {
    return parseInt(loaded / total * 100);
  };

  ProgressbarView.prototype.getRenderData = function() {
    return {
      value: this.value,
      name: this.model.get('name')
    };
  };

  return ProgressbarView;

})(BaseView);
});

;require.register("widgets/tags", function(exports, require, module) {
var Autocomplete, BaseView, TagsView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

BaseView = require('../lib/base_view');

Autocomplete = require('./autocomplete');

module.exports = TagsView = (function(_super) {
  __extends(TagsView, _super);

  function TagsView() {
    this.hideInput = __bind(this.hideInput, this);
    this.toggleInput = __bind(this.toggleInput, this);
    this.refresh = __bind(this.refresh, this);
    this.deleteTag = __bind(this.deleteTag, this);
    this.setTags = __bind(this.setTags, this);
    this.tagClicked = __bind(this.tagClicked, this);
    this.refreshAutocomplete = __bind(this.refreshAutocomplete, this);
    this.onKeyDown = __bind(this.onKeyDown, this);
    return TagsView.__super__.constructor.apply(this, arguments);
  }

  TagsView.prototype.events = function() {
    return {
      'click .tag': 'tagClicked',
      'click .tag .deleter': 'deleteTag',
      'focus input': 'onFocus',
      'keydown input': 'onKeyDown',
      'keyup input': 'refreshAutocomplete'
    };
  };

  TagsView.prototype.template = function() {
    return "<input type=\"text\" placeholder=\"" + (t('tag')) + "\">";
  };

  TagsView.prototype.initialize = function() {
    var tag, tags, _i, _len;
    tags = this.model.get('tags');
    if (tags == null) {
      tags = [];
    }
    this.tags = [];
    for (_i = 0, _len = tags.length; _i < _len; _i++) {
      tag = tags[_i];
      if (tag != null) {
        this.tags.push(tag);
      }
    }
    return this.listenTo(this.model, 'change:tags', (function(_this) {
      return function() {
        _this.tags = _this.model.get('tags');
        return _this.refresh();
      };
    })(this));
  };

  TagsView.prototype.onFocus = function(e) {
    TagsView.autocomplete.bind(this.$el);
    TagsView.autocomplete.refresh('', this.tags);
    if (this.input.val() === '') {
      return TagsView.autocomplete.$el.hide();
    } else {
      return TagsView.autocomplete.$el.show();
    }
  };

  TagsView.prototype.onKeyDown = function(e) {
    var val, _ref, _ref1, _ref2;
    val = this.input.val();
    if (val === '' && e.keyCode === 8) {
      this.setTags(this.tags.slice(0, -1));
      this.refresh();
      TagsView.autocomplete.refresh('', this.tags);
      TagsView.autocomplete.position();
      e.preventDefault();
      e.stopPropagation();
      return;
    }
    if (val && ((_ref = e.keyCode) === 188 || _ref === 32 || _ref === 9 || _ref === 13)) {
      if (this.tags == null) {
        this.tags = [];
      }
      if (__indexOf.call(this.tags, val) < 0) {
        this.tags.push(val);
      }
      this.setTags(this.tags);
      this.input.val('');
      this.refresh();
      TagsView.autocomplete.refresh('', this.tags);
      TagsView.autocomplete.position();
      e.preventDefault();
      e.stopPropagation();
      return;
    }
    if ((_ref1 = e.keyCode) === 188 || _ref1 === 32 || _ref1 === 9 || _ref1 === 13) {
      e.preventDefault();
      e.stopPropagation();
      return;
    }
    if ((_ref2 = e.keyCode) === 40 || _ref2 === 38) {
      return true;
    }
    if (val && e.keyCode !== 8) {
      this.refreshAutocomplete();
      return true;
    }
  };

  TagsView.prototype.refreshAutocomplete = function(e) {
    var _ref;
    if (this.input.val() !== '') {
      TagsView.autocomplete.$el.show();
    }
    if ((_ref = e != null ? e.keyCode : void 0) === 40 || _ref === 38 || _ref === 8) {
      return;
    }
    return TagsView.autocomplete.refresh(this.input.val(), this.tags);
  };

  TagsView.prototype.tagClicked = function(e) {
    var tag;
    tag = e.target.dataset.value;
    return $("#search-box").val("tag:" + tag).trigger('keyup');
  };

  TagsView.prototype.setTags = function(newTags) {
    this.tags = newTags;
    if (this.tags == null) {
      this.tags = [];
    }
    this.refresh();
    clearTimeout(this.saveLater);
    return this.saveLater = setTimeout((function(_this) {
      return function() {
        return _this.model.save({
          tags: _this.tags
        });
      };
    })(this), 1000);
  };

  TagsView.prototype.deleteTag = function(e) {
    var tag;
    tag = e.target.parentNode.dataset.value;
    this.setTags(_.without(this.tags, tag));
    e.stopPropagation();
    return e.preventDefault();
  };

  TagsView.prototype.afterRender = function() {
    this.refresh();
    this.tags = this.model.get('tags');
    return this.input = this.$('input');
  };

  TagsView.prototype.refresh = function() {
    var html, tag;
    this.$('.tag').remove();
    html = ((function() {
      var _i, _len, _ref, _results;
      _ref = this.tags || [];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        tag = _ref[_i];
        _results.push("<li class=\"tag\" data-value=\"" + tag + "\">\n    " + tag + "\n    <span class=\"deleter\"> &times; </span>\n</li>");
      }
      return _results;
    }).call(this)).join('');
    return this.$el.prepend(html);
  };

  TagsView.prototype.toggleInput = function() {
    this.$('input').toggle();
    if (this.$('input').is(':visible')) {
      return this.$('input').focus();
    }
  };

  TagsView.prototype.hideInput = function() {
    return this.$('input').hide();
  };

  return TagsView;

})(BaseView);

TagsView.autocomplete = new Autocomplete({
  id: 'tagsAutocomplete'
});

TagsView.autocomplete.render();
});

;
//# sourceMappingURL=app.js.map