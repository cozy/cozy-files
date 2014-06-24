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
    this.baseCollection = new FileCollection();
    this.uploadQueue = new UploadQueue();
    this.socket = new SocketListener();
    this.socket.watch(this.baseCollection);
    Router = require('router');
    this.router = new Router();
    this.root = new File({
      id: "root",
      path: "",
      name: t('root folder name'),
      type: "folder"
    });
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
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

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
        if (err != null) {
          return callback(err);
        } else {
          _this.add(content, {
            merge: true
          });
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

  FileCollection.prototype.comparator = function(o1, o2) {
    var n1, n2, sort, t1, t2;
    if (this.type == null) {
      this.type = 'name';
    }
    if (this.order == null) {
      this.order = 'incr';
    }
    if (this.type === 'name') {
      n1 = o1.get('name').toLocaleLowerCase();
      n2 = o2.get('name').toLocaleLowerCase();
    } else if (this.type === "lastModification") {
      n1 = new Date(o1.get('lastModification'));
      n2 = new Date(o2.get('lastModification'));
    } else {
      n1 = o1.get(this.type);
      n2 = o2.get(this.type);
    }
    t1 = o1.get('type');
    t2 = o2.get('type');
    sort = this.order === 'incr' ? -1 : 1;
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

;require.register("collections/upload_queue", function(exports, require, module) {
var UploadQueue,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = UploadQueue = (function(_super) {
  __extends(UploadQueue, _super);

  function UploadQueue() {
    return UploadQueue.__super__.constructor.apply(this, arguments);
  }

  UploadQueue.prototype.loaded = 0;

  UploadQueue.prototype.initialize = function() {
    return this.listenTo(this, 'sync', (function(_this) {
      return function() {
        _this.loaded++;
        return _this.trigger('upload-progress', {
          loaded: _this.loaded,
          total: _this.length
        });
      };
    })(this));
  };

  UploadQueue.prototype.isAllLoaded = function() {
    return this.loaded === this.length;
  };

  UploadQueue.prototype.reset = function(models, options) {
    this.loaded = 0;
    return UploadQueue.__super__.reset.call(this, models, options);
  };

  UploadQueue.prototype.processUpload = function(callback) {
    var toUpload;
    toUpload = this.filter(function(file) {
      return !file.isUploaded;
    });
    return async.eachLimit(toUpload, 5, function(file, cb) {
      if (file.error || file.isUploaded) {
        return cb(null);
      }
      return file.save(null, {
        success: function() {
          return cb(null);
        },
        error: function(err) {
          file.error = t(err.msg || "modal error file upload");
          file.trigger('sync');
          return cb(null);
        }
      });
    }, callback);
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
  return app.initialize();
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

;require.register("lib/socket", function(exports, require, module) {
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

  SocketListener.prototype.isInCachedFolder = function(model) {
    var path;
    path = model.get('path');
    return this.collection.isPathCached(path);
  };

  SocketListener.prototype.onRemoteCreate = function(model) {
    if (this.isInCachedFolder(model)) {
      console.info("remote create", model);
      if (!(this.collection.get(model.get("id")))) {
        return this.collection.add(model, {
          merge: true
        });
      }
    }
  };

  SocketListener.prototype.onRemoteDelete = function(model) {
    if (this.isInCachedFolder(model)) {
      console.info("remote delete", model);
      return this.collection.remove(model);
    }
  };

  SocketListener.prototype.onRemoteUpdate = function(model, collection) {
    if (this.isInCachedFolder(model)) {
      console.info("remote update", model);
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

  ViewCollection.prototype.onChange = function() {
    return this.$el.toggleClass('empty', _.size(this.views) === 0);
  };

  ViewCollection.prototype.appendView = function(view) {
    return this.$collectionEl.append(view.el);
  };

  ViewCollection.prototype.initialize = function() {
    ViewCollection.__super__.initialize.apply(this, arguments);
    this.views = {};
    this.listenTo(this.collection, "reset", this.onReset);
    this.listenTo(this.collection, "add", this.addItem);
    this.listenTo(this.collection, "remove", this.removeItem);
    if (this.collectionEl == null) {
      return this.collectionEl = el;
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
  "modal error get content": "An error occurred while retrieving content of folder \"%{folderName}\" from the server",
  "modal error empty name": "The name can't be empty",
  "modal error file invalid": "doesn't seem to be a valid file",
  "root folder name": "root",
  "breadcrumbs search title": "Search",
  "modal error file exists": "Sorry, a file or folder having this name already exists",
  "modal error file upload": "File could not be sent to server",
  "modal error folder create": "Folder could not be created",
  "modal error folder exists": "Sorry, a file or folder having this name already exists",
  "modal error zip empty folder": "You can't download an empty folder as a ZIP.",
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
  "drop message": "Drop your files here to automatically add them",
  "upload folder msg": "Upload a folder",
  "upload folder separator": "or",
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
  "modal shared folder link msg": "Send this link to let people access this folder",
  "modal send mails": "Send a notification",
  "modal question file shareable": "Select share mode for this file",
  "modal shared file custom msg": "Enter email and press enter",
  "modal shared file link msg": "Send this link to let people access this file",
  "only you can see": "Only you and the people listed below can access this resource",
  "public": "Public",
  "private": "Private",
  "shared": "Shared",
  "save": "Save",
  "see link": "See link",
  "send mails question": "Send a notification email to:",
  "sharing": "Sharing",
  "revoke": "Revoke",
  "forced public": "This is public because one of the parent folder is public:",
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
  'move': 'Move',
  'tooltip move': 'Move element to another folder.',
  "moving...": 'Moving...',
  'move element to': 'Move element to',
  'error occured canceling move': 'An error occured while canceling move.',
  'error occured while moving element': 'An error occured while moving element',
  'file successfully moved to': 'File successfully move to'
};
});

;require.register("locales/fr", function(exports, require, module) {
module.exports = {
  "modal error": "Erreur",
  "modal ok": "OK",
  "modal error get files": "Une erreur s'est produite en récupérant les fichiers du serveur",
  "modal error get folders": "Une erreur s'est produite en récupérant les dossiers du serveur",
  "modal error get content": "Une erreur s'est produite en récupérant le contenu du dossier \"%{folderName}\" sur le serveur",
  "modal error empty name": "Le nom ne peut pas être vide",
  "modal error file invalid": "Le fichier ne parait pas être valide",
  "root folder name": "racine",
  "breadcrumbs search title": "Recherche",
  "modal error file exists": "Désolé, un fichier ou un dossier a déjà le même nom",
  "modal error file upload": "Le fichier n'a pas pu être envoyé au serveur",
  "modal error folder create": "Le dossier n'a pas pu être créé",
  "modal error folder exists": "Désolé, un fichier ou un dossier a déjà le même nom",
  "modal error zip empty folder": "Vous ne pouvez pas télécharger un dossier vide en tant que ZIP.",
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
  "upload caption": "Ajouter des fichiers",
  "upload msg": "Glissez des fichiers ou cliquez ici pour sélectionner des fichiers à mettre en ligne.",
  "upload msg selected": "Vous avez sélectionné %{smart_count} fichier, cliquez sur \"Ajouter\" pour les mettre en ligne. ||||\nVous avez sélectionné %{smart_count} fichiers, cliquez sur \"Ajouter\" pour les mettre en ligne.",
  "upload close": "Annuler",
  "upload send": "Ajouter",
  "upload button": "Ajouter un fichier",
  "upload success": "Ajouté avec succès !",
  "upload end button": "Fermer",
  "total progress": "Progression totale",
  "new folder caption": "Créer un nouveau dossier",
  "new folder msg": "Entrer le nom du dossier :",
  "new folder close": "Annuler",
  "new folder send": "Créer",
  "new folder button": "Créer un nouveau dossier",
  "drop message": "Lâchez ici vos fichiers pour les ajouter",
  "upload folder msg": "Mettre en ligne un dossier",
  "upload folder separator": "ou",
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
  "files": "fichiers",
  "element": "%{smart_count} élément |||| %{smart_count} éléments",
  "no file in folder": "Ce dossier est vide.",
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
  "public": "Public",
  "private": "Privé",
  "shared": "Partagé",
  "save": "Sauvegarder",
  "see link": "Voir le lien",
  "sharing": "Partage",
  "revoke": "Révoquer la permission",
  "send mails question": "Envoyer un email de notification à : ",
  "modal send mails": "Envoyer une notification",
  "forced public": "Ce dossier est public car un parent est public : ",
  "confirm": "Confirmer",
  "share forgot add": "Il semble que vous ayez oublié d'appuyer sur le boutton Add",
  "share confirm save": "Les changements effectués sur les permissions ne seront pas sauvegardés. Etes vous sur ?",
  "yes forgot": "Retour",
  "no forgot": "Ok",
  "perm": "peut ",
  "perm r file": "consulter ce fichier",
  "perm r folder": "parcourir ce dossier",
  "perm rw folder": "parcourir ce dossier et ajouter des fichiers",
  "change notif": "Cocher cette case pour recevoir une notification cozy quand un contact\najoute un fichier à ce dossier.",
  "move": "Déplacer",
  'tooltip move': "Déplacer l'élément dans un autre dossier.",
  "moving...": "Déplacement en cours...",
  "move element to": "Déplacer l'élément vers ",
  "error occured canceling move": "Une erreur est survenue en annulant le déplacement.",
  "error occured while moving element": "Une erreur est survenue en déplaçant l'élément.",
  "file successfully moved to": 'Fichier déplacé avec succès vers '
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
  "change notif": "Bifați această casetă pentru a fi notificat atunci când o persoană de contact\nadăuga un fișier în acest dosar."
};
});

;require.register("models/file", function(exports, require, module) {
var File, client,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

client = require('../lib/client');

module.exports = File = (function(_super) {
  __extends(File, _super);

  File.prototype.breadcrumb = null;

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

  File.prototype.isRoot = function() {
    return this.get('id') === 'root';
  };

  File.prototype.sync = function(method, model, options) {
    var formdata, progress;
    if (model.file) {
      formdata = new FormData();
      formdata.append('name', model.get('name'));
      formdata.append('path', model.get('path'));
      formdata.append('file', model.file);
      formdata.append('lastModification', model.get('lastModification'));
      progress = function(e) {
        return model.trigger('progress', e);
      };
      _.extend(options, {
        contentType: false,
        data: formdata,
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
    }
    this.isUploaded = true;
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
    return this.getRepository();
  };

  File.prototype.getRepository = function() {
    if (this.get('id') === "root") {
      return "";
    } else {
      return "" + (this.get("path")) + "/" + (this.get("name"));
    }
  };

  File.prototype.getPublicURL = function(key) {
    return "" + window.location.origin + "/public/files/" + (this.urlRoot()) + this.id;
  };


  /*
      ONLY RELEVANT IF IT'S A FOLDER
      Fetches content (folders and files) for the current folder
      the request also responds with the breadcrumb
   */

  File.prototype.fetchContent = function(callbacks) {
    this.prepareCallbacks(callbacks);
    return client.post("" + (this.urlRoot()) + "content", {
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
          _this.setBreadcrumb(parents);
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
      return this.breadcrumb = parents;
    }
  };

  return File;

})(Backbone.Model);
});

;require.register("router", function(exports, require, module) {
var File, FileCollection, FolderView, Router, app,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

app = require('application');

File = require('./models/file');

FileCollection = require('./collections/files');

FolderView = require('./views/folder');


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
    if (query == null) {
      query = '';
    }
    if (this.folderView != null) {
      this.folderView.destroy();
      $('html').append($('<body></body>'));
    }
    this.folderView = new FolderView({
      model: folder,
      collection: collection,
      baseCollection: app.baseCollection,
      breadcrumbs: app.breadcrumbs,
      uploadQueue: app.uploadQueue,
      query: query
    });
    return this.folderView.render();
  };

  return Router;

})(Backbone.Router);
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
var BaseView, FileView, ModalShareView, ModalView, TagsView, client,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

ModalView = require("./modal");

ModalShareView = require("./modal_share");

TagsView = require("./tags");

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
    'click a.file-delete': 'onDeleteClicked',
    'click a.file-share': 'onShare',
    'click a.file-edit': 'onEditClicked',
    'click a.file-edit-save': 'onSaveClicked',
    'click a.file-edit-cancel': 'render',
    'click a.file-move': 'onMoveClicked',
    'keydown input': 'onKeyPress'
  };

  FileView.prototype.template = function(args) {
    if (this.isSearchMode) {
      return this.templateSearch(args);
    } else {
      return this.templateNormal(args);
    }
  };

  FileView.prototype.initialize = function(options) {
    this.isSearchMode = options.isSearchMode;
    return this.listenTo(this.model, 'change', this.render);
  };

  FileView.prototype.onDeleteClicked = function() {
    return new ModalView(t("modal are you sure"), t("modal delete msg"), t("modal delete ok"), t("modal cancel"), (function(_this) {
      return function(confirm) {
        if (confirm) {
          return _this.model.destroy({
            error: function() {
              return ModalView.error(t("modal delete error"));
            }
          });
        }
      };
    })(this));
  };

  FileView.prototype.onEditClicked = function() {
    var input, lastIndexOfDot, model, range, width;
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
    this.$(".file-edit-name").focus();
    lastIndexOfDot = model.name.lastIndexOf('.');
    if (lastIndexOfDot === -1) {
      lastIndexOfDot = model.name.length;
    }
    input = this.$(".file-edit-name")[0];
    if (typeof input.selectionStart !== "undefined") {
      input.selectionStart = 0;
      return input.selectionEnd = lastIndexOfDot;
    } else if (document.selection && document.selection.createRange) {
      input.select();
      range = document.selection.createRange();
      range.collapse(true);
      range.moveEnd("character", lastIndexOfDot);
      range.moveStart("character", 0);
      return range.select();
    }
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
            if (err.status === 400) {
              return ModalView.error(t("modal error in use"));
            } else {
              return ModalView.error(t("modal error rename"));
            }
          };
        })(this)
      });
    } else {
      return ModalView.error(t("modal error empty name"));
    }
  };

  FileView.prototype.onMoveClicked = function() {
    var errorTemplate, firstCell, formTemplate, movedTemplate, optionTemplate;
    formTemplate = "<div class=\"move-widget\">\n<span> " + (t('move element to')) + ": </span>\n<select class=\"move-select\"></select>\n<button class=\"button btn move-btn\">\n    " + (t('move')) + "\n</button>\n<button class=\"btn btn-link cancel-move-btn\">\n    " + (t('cancel')) + "\n</button>\n</div>";
    errorTemplate = "<div>\n    <span class=\"error\">\n    " + 'error occured while moving element' + ": " + (this.model.get('name')) + ".\n    #</span>\n</div>";
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
          return alert(err);
        } else {
          parentPath = _this.model.get('path');
          fullPath = _this.model.get('path') + "/" + _this.model.get('name');
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
              if (err) {
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
        isSearchMode: options.isSearchMode
      };
    };
    this.chevron = {
      order: this.collection.order,
      type: this.collection.type
    };
    this.listenTo(this.collection, "add", this.render);
    this.listenTo(this.collection, "remove", this.render);
    this.listenTo(this.collection, "sort", this.render);
    return this.listenTo(this.collection, "reset", this.render);
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

  FilesView.prototype.onChangeOrder = function(event) {
    var infos, order, type;
    infos = event.target.id.split('-');
    order = infos[0];
    type = infos[1];
    this.chevron = {
      order: order,
      type: type
    };
    order = order === 'down' ? 'decr' : 'incr';
    this.collection.order = order;
    this.collection.type = type;
    return this.collection.sort();
  };

  return FilesView;

})(ViewCollection);
});

;require.register("views/folder", function(exports, require, module) {
var BaseView, BreadcrumbsView, File, FileCollection, FilesView, FolderView, ModalFolderView, ModalShareView, ModalUploadView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

FilesView = require('./files');

BreadcrumbsView = require("./breadcrumbs");

ModalUploadView = require('./modal_upload');

ModalFolderView = require('./modal_folder');

ModalShareView = require('./modal_share');

File = require('../models/file');

FileCollection = require('../collections/files');


/*
Handles the display logic for a folder.
Main entry point of the interface: handles breadcrumb, buttons and files list
 */

module.exports = FolderView = (function(_super) {
  __extends(FolderView, _super);

  function FolderView() {
    this.validateNewModel = __bind(this.validateNewModel, this);
    return FolderView.__super__.constructor.apply(this, arguments);
  }

  FolderView.prototype.el = 'body';

  FolderView.prototype.template = require('./templates/folder');

  FolderView.prototype.events = function() {
    return {
      'click #button-new-folder': 'onNewFolderClicked',
      'click #button-upload-new-file': 'onUploadNewFileClicked',
      'click #new-folder-send': 'onAddFolder',
      'click #cancel-new-folder': 'onCancelFolder',
      'click #cancel-new-file': 'onCancelFile',
      'click #share-state': 'onShareClicked',
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
    return this.query = options.query;
  };

  FolderView.prototype.destroy = function() {
    this.breadcrumbsView.destroy();
    this.breadcrumbsView = null;
    this.filesList.destroy();
    this.filesList = null;
    return FolderView.__super__.destroy.call(this);
  };

  FolderView.prototype.getRenderData = function() {
    return {
      model: this.model.toJSON(),
      query: this.query
    };
  };

  FolderView.prototype.afterRender = function() {
    this.uploadButton = this.$('#button-upload-new-file');
    this.renderBreadcrumb();
    this.renderFileList();
    return this.refreshData();
  };

  FolderView.prototype.renderBreadcrumb = function() {
    this.$('#crumbs').empty();
    this.breadcrumbsView = new BreadcrumbsView({
      collection: this.model.breadcrumb
    });
    return this.$("#crumbs").append(this.breadcrumbsView.render().$el);
  };

  FolderView.prototype.renderFileList = function() {
    this.filesList = new FilesView({
      model: this.model,
      collection: this.collection,
      isSearchMode: this.model.get('type') === "search"
    });
    return this.filesList.render();
  };

  FolderView.prototype.spin = function(state) {
    if (state == null) {
      state = 'small';
    }
    return this.$("#loading-indicator").spin(state);
  };

  FolderView.prototype.refreshData = function() {
    this.spin();
    return this.baseCollection.getFolderContent(this.model, (function(_this) {
      return function() {
        return _this.spin(false);
      };
    })(this));
  };


  /*
      Button handlers
   */

  FolderView.prototype.onUploadNewFileClicked = function() {
    return this.modal = new ModalUploadView({
      model: this.model,
      validator: this.validateNewModel,
      uploadQueue: this.uploadQueue
    });
  };

  FolderView.prototype.onNewFolderClicked = function() {
    return this.modal = new ModalFolderView({
      model: this.model,
      validator: this.validateNewModel,
      uploadQueue: this.uploadQueue
    });
  };

  FolderView.prototype.onShareClicked = function() {
    return new ModalShareView({
      model: this.model
    });
  };

  FolderView.prototype.validateNewModel = function(model) {
    var found, myChildren;
    myChildren = model.get('path') === this.model.getRepository();
    found = this.filesList.collection.findWhere({
      name: model.get('name')
    });
    if (myChildren && found) {
      return t('modal error file exists');
    } else {
      return null;
    }
  };


  /*
      Drag and Drop to upload
   */

  FolderView.prototype.onDragStart = function(e) {
    e.preventDefault();
    return e.stopPropagation();
  };

  FolderView.prototype.onDragEnter = function(e) {
    e.preventDefault();
    e.stopPropagation();
    this.uploadButton.addClass('btn-cozy-contrast');
    return this.$('#files-drop-zone').show();
  };

  FolderView.prototype.onDragLeave = function(e) {
    e.preventDefault();
    e.stopPropagation();
    this.uploadButton.removeClass('btn-cozy-contrast');
    return this.$('#files-drop-zone').hide();
  };

  FolderView.prototype.onDrop = function(e) {
    var filesToUpload;
    e.preventDefault();
    e.stopPropagation();
    filesToUpload = e.dataTransfer.files;
    if (filesToUpload.length > 0) {
      this.modal = new ModalUploadView({
        model: this.model,
        validator: this.validateNewModel,
        files: filesToUpload,
        uploadQueue: this.uploadQueue
      });
    }
    this.uploadButton.removeClass('btn-cozy-contrast');
    return this.$('#files-drop-zone').hide();
  };


  /*
      Search
   */

  FolderView.prototype.onSearchKeyPress = function(e) {
    var query, route;
    query = this.$('input#search-box').val();
    if (query !== '') {
      route = "#search/" + query;
    } else {
      route = '';
    }
    return window.app.router.navigate(route, true);
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
    this.$el.on('hidden.bs.modal', (function(_this) {
      return function() {
        return _this.close();
      };
    })(this));
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
    return setTimeout(((function(_this) {
      return function() {
        return _this.destroy();
      };
    })(this)), 500);
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

;require.register("views/modal_folder", function(exports, require, module) {
var BaseView, Client, File, Helpers, Modal, ModalFolderView, ModalUploadView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

Modal = require("./modal");

Helpers = require('../lib/folder_helpers');

File = require('../models/file');

ModalUploadView = require('./modal_upload');

Client = require("../lib/client");

module.exports = ModalFolderView = (function(_super) {
  __extends(ModalFolderView, _super);

  ModalFolderView.prototype.id = "dialog-new-folder";

  ModalFolderView.prototype.className = "modal fade";

  ModalFolderView.prototype.attributes = {
    'tab-index': -1
  };

  ModalFolderView.prototype.template = require('./templates/modal_folder');

  function ModalFolderView(options, callback) {
    this.onYes = __bind(this.onYes, this);
    this.doUploadFolder = __bind(this.doUploadFolder, this);
    this.doCreateFolder = __bind(this.doCreateFolder, this);
    this.onUploaderChange = __bind(this.onUploaderChange, this);
    this.onKeyUp = __bind(this.onKeyUp, this);
    this.onShow = __bind(this.onShow, this);
    this.hideAndDestroy = __bind(this.hideAndDestroy, this);
    this.uploadQueue = options.uploadQueue;
    Modal.__super__.constructor.apply(this, arguments);
    this.callback = callback;
    this.validator = options.validator;
  }

  ModalFolderView.prototype.events = function() {
    return _.extend(ModalFolderView.__super__.events.apply(this, arguments), {
      'keyup #inputName': 'onKeyUp',
      'change #folder-uploader': 'onUploaderChange'
    });
  };

  ModalFolderView.prototype.initialize = function() {
    ModalFolderView.__super__.initialize.apply(this, arguments);
    return this.prefix = this.model.repository();
  };

  ModalFolderView.prototype.afterRender = function() {
    var supportsDirectoryUpload, uploadDirectoryInput;
    uploadDirectoryInput = this.$("#folder-uploader")[0];
    supportsDirectoryUpload = uploadDirectoryInput.directory || uploadDirectoryInput.mozdirectory || uploadDirectoryInput.webkitdirectory || uploadDirectoryInput.msdirectory;
    if (supportsDirectoryUpload) {
      this.$("#folder-upload-form").removeClass('hide');
    }
    this.uploader = this.$('#folder-uploader');
    this.inputName = this.$('#inputName');
    this.submitButton = this.$("#modal-dialog-yes");
    return this.$el.on('show', this.onShow);
  };

  ModalFolderView.prototype.hideAndDestroy = function() {
    this.hide();
    return setTimeout((function(_this) {
      return function() {
        return _this.destroy();
      };
    })(this), 500);
  };

  ModalFolderView.prototype.onShow = function() {
    return setTimeout((function(_this) {
      return function() {
        return _this.inputName.focus();
      };
    })(this), 500);
  };

  ModalFolderView.prototype.onKeyUp = function(event) {
    if (event.keyCode === 13) {
      event.preventDefault();
      event.stopPropagation();
      return this.onYes();
    } else {
      this.action = 'create';
      this.uploader.val('');
      if (this.inputName.val().length > 0) {
        return this.enableCreateButtonState();
      } else {
        return this.disableCreateButtonState();
      }
    }
  };

  ModalFolderView.prototype.onUploaderChange = function() {
    this.action = 'upload';
    this.inputName.val('');
    return this.enableCreateButtonState();
  };

  ModalFolderView.prototype.enableCreateButtonState = function() {
    var element;
    element = $('#modal-dialog-yes');
    if (element.prop('disabled')) {
      return element.prop('disabled', 'false').button('refresh');
    }
  };

  ModalFolderView.prototype.disableCreateButtonState = function() {
    var element;
    element = $('#modal-dialog-yes');
    if (!element.prop('disabled')) {
      return element.prop('disabled', 'true');
    }
  };

  ModalFolderView.prototype.doSaveFolder = function(folder, callback) {
    var err;
    if (err = this.validator(folder)) {
      return Modal.error(t("modal error folder exists"));
    }
    this.submitButton.html('&nbsp;').spin('tiny');
    return folder.save(null, {
      always: function() {
        return this.submitButton.spin(false).text(t('new folder send'));
      },
      success: (function(_this) {
        return function(data) {
          _this.hideAndDestroy();
          return callback(null);
        };
      })(this),
      error: function(_, err) {
        if (err.status === 400) {
          Modal.error(t("modal error folder exists"));
        } else {
          Modal.error(t("modal error folder create"));
        }
        return callback(err);
      }
    });
  };

  ModalFolderView.prototype.doCreateFolder = function(callback) {
    var errors, folder;
    folder = new File({
      name: this.$('#inputName').val(),
      path: this.prefix,
      type: "folder"
    });
    if (errors = folder.validate()) {
      return Modal.error(t("modal error no data"));
    }
    return this.doSaveFolder(folder, callback);
  };

  ModalFolderView.prototype.doUploadFolder = function(callback) {
    var dirs, files;
    files = this.$('#folder-uploader')[0].files;
    if (!files.length) {
      return Modal.error(t("modal error no data"));
    }
    dirs = Helpers.nestedDirs(files);
    return async.each(dirs, (function(_this) {
      return function(dir, cb) {
        var folder, parts, path;
        dir = Helpers.removeTralingSlash(dir);
        parts = dir.split('/');
        path = "" + _this.prefix + "/" + (parts.slice(0, -1).join('/'));
        path = Helpers.removeTralingSlash(path);
        folder = new File({
          name: parts.slice(-1)[0],
          path: path,
          type: "folder"
        });
        return _this.doSaveFolder(folder, function(err) {
          if (err) {
            console.log(err);
          }
          return cb(null);
        });
      };
    })(this), (function(_this) {
      return function(err) {
        var file, relPath, _i, _len;
        files = _.filter(files, function(file) {
          var _ref;
          return (_ref = file.name) !== '.' && _ref !== '..';
        });
        for (_i = 0, _len = files.length; _i < _len; _i++) {
          file = files[_i];
          relPath = file.relativePath || file.mozRelativePath || file.webkitRelativePath || file.msRelativePath;
          file.path = "" + _this.prefix + "/" + (Helpers.dirName(relPath));
        }
        return new ModalUploadView({
          model: _this.model,
          files: files,
          validator: function() {
            return null;
          },
          uploadQueue: _this.uploadQueue
        });
      };
    })(this));
  };

  ModalFolderView.prototype.onYes = function() {
    var doStuff;
    doStuff = this.action === 'upload' ? this.doUploadFolder : this.doCreateFolder;
    return doStuff(function() {
      return console.log(arguments);
    });
  };

  return ModalFolderView;

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
        var last;
        if (err) {
          return Modal.error('server error occured', function() {
            return _this.$el.modal('hide');
          });
        } else {
          _this.inherited = data.inherited;
          last = _.last(_this.inherited);
          if ((last != null ? last.clearance : void 0) === 'public') {
            _this.forcedPublic = last.name;
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

;require.register("views/modal_upload", function(exports, require, module) {
var File, Modal, ModalUploadView, ProgressBar, UploadedFileView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Modal = require('./modal');

File = require('../models/file');

ProgressBar = require('../widgets/progressbar');

UploadedFileView = require('./uploaded_file_view');

module.exports = ModalUploadView = (function(_super) {
  __extends(ModalUploadView, _super);

  ModalUploadView.prototype.id = "dialog-upload-file";

  ModalUploadView.prototype.className = "modal fade";

  ModalUploadView.prototype.attributes = {
    'tab-index': -1
  };

  ModalUploadView.prototype.template = require('./templates/modal_upload');

  ModalUploadView.prototype.events = function() {
    return _.extend(ModalUploadView.__super__.events.apply(this, arguments), {
      'dragover': 'onDragEnter',
      'dragenter': 'onDragEnter',
      'dragleave': 'onDragLeave',
      'drop': 'onDrop',
      'change #uploader': 'onUploaderChange',
      'mousedown #uploader': 'handleUploaderActive'
    });
  };

  function ModalUploadView(options, callback) {
    this.doUploadFiles = __bind(this.doUploadFiles, this);
    this.onDrop = __bind(this.onDrop, this);
    this.onUploaderChange = __bind(this.onUploaderChange, this);
    this.updateMessage = __bind(this.updateMessage, this);
    this.handleUploaderActive = __bind(this.handleUploaderActive, this);
    this.afterRender = __bind(this.afterRender, this);
    var _ref;
    this.uploadQueue = options.uploadQueue;
    Modal.__super__.constructor.apply(this, arguments);
    this.callback = callback;
    this.validator = options.validator;
    this.files = options.files;
    this.views = {};
    if (((_ref = this.files) != null ? _ref.length : void 0) > 0) {
      this.onYes();
    }
  }

  ModalUploadView.prototype.initialize = function() {
    this.listenTo(this.uploadQueue, 'add', this.afterRender);
    this.listenTo(this.uploadQueue, 'upload-progress', (function(_this) {
      return function(progress) {
        _this.totalProgress.trigger('progress', progress);
        if (_this.uploadQueue.isAllLoaded()) {
          return _this.afterRender();
        }
      };
    })(this));
    return ModalUploadView.__super__.initialize.call(this);
  };

  ModalUploadView.prototype.afterRender = function() {
    var noButton;
    this.input = this.$('#uploader input');
    this.label = this.$('#uploader .text');
    if (this.uploadQueue.length > 0) {
      noButton = $('#modal-dialog-no');
      noButton.html('&nbsp;');
      noButton.spin('small');
      this.subRenderTotalProgressBar();
      this.subRenderFileUploadProgress();
      if (this.uploadQueue.isAllLoaded()) {
        noButton = $('#modal-dialog-no');
        noButton.spin(false);
        noButton.html(t('upload end button'));
        return this.uploadQueue.reset();
      }
    }
  };

  ModalUploadView.prototype.subRenderTotalProgressBar = function() {
    var progressbar;
    this.$('#progress-total').empty();
    this.views = [];
    this.totalProgress = new Backbone.Model();
    this.totalProgress.loaded = this.uploadQueue.loaded;
    this.totalProgress.total = this.uploadQueue.length;
    progressbar = new ProgressBar({
      model: this.totalProgress
    }).render();
    $("<span>" + (t('total progress')) + "</span>").appendTo(this.$('#progress-total'));
    return progressbar.$el.appendTo(this.$('#progress-total'));
  };

  ModalUploadView.prototype.subRenderFileUploadProgress = function() {
    var filesEl;
    this.$('#progress-part').empty();
    filesEl = [];
    _.map(Object.keys(this.views), (function(_this) {
      return function(viewID) {
        return _this.views[viewID].$el.detach();
      };
    })(this));
    return this.uploadQueue.forEach((function(_this) {
      return function(uploadingFile) {
        var uploadEl, uploadView;
        uploadView = _this.views[uploadingFile.cid];
        if (uploadView == null) {
          uploadEl = new UploadedFileView({
            model: uploadingFile
          });
          _this.views[uploadingFile.cid] = uploadEl;
        }
        return _this.$('#progress-part').append(uploadEl.render().$el);
      };
    })(this));
  };

  ModalUploadView.prototype.onNo = function() {
    this.input.val("");
    this.hide();
    return setTimeout(((function(_this) {
      return function() {
        return _this.destroy();
      };
    })(this)), 500);
  };

  ModalUploadView.prototype.onYes = function() {
    return this.doUploadFiles((function(_this) {
      return function() {
        return typeof _this.callback === "function" ? _this.callback() : void 0;
      };
    })(this));
  };

  ModalUploadView.prototype.handleUploaderActive = function() {
    this.$('#uploader').addClass('active');
    return $(document).one('mouseup', (function(_this) {
      return function() {
        return _this.$('#uploader').removeClass('active');
      };
    })(this));
  };

  ModalUploadView.prototype.updateMessage = function() {
    var msg;
    if (this.files.length) {
      msg = t('upload msg selected', {
        smart_count: this.files.length
      });
      $('#modal-dialog-yes').prop("disabled", false);
    } else {
      msg = t('upload msg');
      $('#modal-dialog-yes').prop("disabled", true);
    }
    return this.label.text(msg);
  };

  ModalUploadView.prototype.onUploaderChange = function(e) {
    this.files = this.input[0].files;
    return this.updateMessage();
  };

  ModalUploadView.prototype.onDragEnter = function(e) {
    e.preventDefault();
    e.stopPropagation();
    return this.$('.modal-body').css('background-color', 'yellow');
  };

  ModalUploadView.prototype.onDragLeave = function(e) {
    e.preventDefault();
    e.stopPropagation();
    return this.$('.modal-body').css('background-color', '');
  };

  ModalUploadView.prototype.onDrop = function(e) {
    e.preventDefault();
    e.stopPropagation();
    this.files = _.filter(e.dataTransfer.files, function(attach) {
      return attach.type !== '';
    });
    return this.updateMessage();
  };

  ModalUploadView.prototype.doUploadFiles = function(callback) {
    var models;
    models = _.map(this.files, (function(_this) {
      return function(blob) {
        var fileModel;
        fileModel = new File({
          type: 'file',
          name: blob.name,
          path: blob.path || _this.model.getRepository(),
          lastModification: blob.lastModifiedDate
        });
        fileModel.file = blob;
        fileModel.loaded = 0;
        fileModel.total = blob.size;
        fileModel.error = _this.validator(fileModel);
        return fileModel;
      };
    })(this));
    this.uploadQueue.add(models);
    this.uploadQueue.processUpload(callback);
    this.files = [];
    this.input.val("");
    return this.updateMessage();
  };

  ModalUploadView.prototype.destroy = function() {
    this.stopListening(this.uploadQueue);
    return ModalUploadView.__super__.destroy.call(this);
  };

  return ModalUploadView;

})(Modal);
});

;require.register("views/public_folder", function(exports, require, module) {
var File, FileCollection, FilesView, FolderView, Modal, PublicFilesView, PublicFolderView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

window.CozySocketListener = {
  fake: ''
};

FolderView = require('./folder');

File = require('../models/file');

FilesView = require('./files');

FileCollection = require('../collections/files');

Modal = require('./modal');

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
    this.uploadQueue = options.uploadQueue;
    old = File.prototype.urlRoot;
    File.prototype.urlRoot = function() {
      return '../' + old.apply(this, arguments) + window.location.search;
    };
    this.collection = new FileCollection([]);
    this.filesList = new PublicFilesView(this.collection, this.model);
    return this.$('#download-link').click(function(event) {
      if (window.numElements === 0) {
        event.preventDefault();
        return Modal.error(t('modal error zip empty folder'));
      }
    });
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
      availableTags: window.tags || [],
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
var locals_ = (locals || {}),model = locals_.model,options = locals_.options;
buf.push("<td><div class=\"caption-wrapper\">");
if ( model.type == 'folder')
{
buf.push("<a" + (jade.attr("href", "#folders/" + (model.id) + "", true, false)) + (jade.attr("title", "" + (t('open folder')) + "", true, false)) + " class=\"caption btn btn-link\"><i class=\"fa fa-folder\"></i>" + (jade.escape((jade_interp = model.name) == null ? '' : jade_interp)) + "</a>");
}
else if ( model.type == 'file')
{
buf.push("<a" + (jade.attr("href", "files/" + (model.id) + "/attach/" + (model.name) + "", true, false)) + (jade.attr("title", "" + (t('download file')) + "", true, false)) + " target=\"_blank\" class=\"caption btn btn-link\"><i class=\"fa fa-file-o\"></i>" + (jade.escape((jade_interp = model.name) == null ? '' : jade_interp)) + "</a>");
}
buf.push("<ul class=\"tags\">");
if ( model.tags)
{
// iterate model.tags
;(function(){
  var $$obj = model.tags;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var tag = $$obj[$index];

buf.push("<li>" + (jade.escape((jade_interp = tag) == null ? '' : jade_interp)) + "</li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var tag = $$obj[$index];

buf.push("<li>" + (jade.escape((jade_interp = tag) == null ? '' : jade_interp)) + "</li>");
    }

  }
}).call(this);

}
buf.push("</ul><div class=\"operations\"><a" + (jade.attr("title", "" + (t('tooltip share')) + "", true, false)) + " class=\"file-share\">");
if ( model.clearance == 'public')
{
buf.push("<span class=\"fa fa-globe\"></span>");
}
else if ( model.clearance && model.clearance.length > 0)
{
buf.push("<span class=\"fa fa-users\">" + (jade.escape((jade_interp = model.clearance.length) == null ? '' : jade_interp)) + "</span>");
}
else
{
buf.push("<span class=\"fa fa-lock\"></span>");
}
buf.push("</a><a" + (jade.attr("title", "" + (t('tooltip edit')) + "", true, false)) + " class=\"file-edit\"><span class=\"glyphicon glyphicon-edit\"></span></a><a" + (jade.attr("title", "" + (t('tooltip move')) + "", true, false)) + " class=\"file-move\"><span class=\"glyphicon glyphicon-arrow-right\"></span></a><a" + (jade.attr("title", "" + (t('tooltip delete')) + "", true, false)) + " class=\"file-delete\"><span class=\"glyphicon glyphicon-remove-circle\"></span></a><a" + (jade.attr("href", "folders/" + (model.id) + "/zip/" + (model.name) + "", true, false)) + " target=\"_blank\"" + (jade.attr("title", "" + (t('tooltip download')) + "", true, false)) + " class=\"file-download\"><span class=\"glyphicon glyphicon-cloud-download\"></span></a></div></div><!-- empty by default--></td><td class=\"size-column-cell\">");
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
var locals_ = (locals || {}),model = locals_.model,options = locals_.options;
buf.push("<td><div class=\"caption-wrapper\"><span class=\"caption caption-edit btn-link\">");
if ( model.type && model.type == "folder")
{
buf.push("<i class=\"fa fa-folder\"></i>");
}
else
{
buf.push("<i class=\"fa fa-file-o\"></i>");
}
buf.push("<input" + (jade.attr("value", model.name, true, false)) + " class=\"caption file-edit-name\"/></span><a class=\"btn btn-sm btn-cozy file-edit-save\">" + (jade.escape((jade_interp = t("file edit save")) == null ? '' : jade_interp)) + "</a><a class=\"btn btn-sm btn-link file-edit-cancel\">" + (jade.escape((jade_interp = t("file edit cancel")) == null ? '' : jade_interp)) + "</a><!-- empty!--></div><!-- empty by default--></td><td class=\"size-column-cell\">");
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
var locals_ = (locals || {}),model = locals_.model,options = locals_.options;
buf.push("<td><div class=\"caption-wrapper\">");
if ( model.type == 'folder')
{
buf.push("<a" + (jade.attr("href", "#folders/" + (model.id) + "", true, false)) + (jade.attr("title", "" + (t('open folder')) + "", true, false)) + " class=\"caption btn btn-link\"><i class=\"fa fa-folder\"></i>" + (jade.escape((jade_interp = model.name) == null ? '' : jade_interp)) + "</a>");
}
else if ( model.type == 'file')
{
buf.push("<a" + (jade.attr("href", "files/" + (model.id) + "/attach/" + (model.name) + "", true, false)) + (jade.attr("title", "" + (t('download file')) + "", true, false)) + " target=\"_blank\" class=\"caption btn btn-link\"><i class=\"fa fa-file-o\"></i>" + (jade.escape((jade_interp = model.name) == null ? '' : jade_interp)) + "</a>");
}
buf.push("<ul class=\"tags\">");
if ( model.tags)
{
// iterate model.tags
;(function(){
  var $$obj = model.tags;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var tag = $$obj[$index];

buf.push("<li>" + (jade.escape((jade_interp = tag) == null ? '' : jade_interp)) + "</li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var tag = $$obj[$index];

buf.push("<li>" + (jade.escape((jade_interp = tag) == null ? '' : jade_interp)) + "</li>");
    }

  }
}).call(this);

}
buf.push("</ul><div class=\"operations\"><a" + (jade.attr("title", "" + (t('tooltip share')) + "", true, false)) + " class=\"file-share\">");
if ( model.clearance == 'public')
{
buf.push("<span class=\"fa fa-globe\"></span>");
}
else if ( model.clearance && model.clearance.length > 0)
{
buf.push("<span class=\"fa fa-users\">" + (jade.escape((jade_interp = model.clearance.length) == null ? '' : jade_interp)) + "</span>");
}
else
{
buf.push("<span class=\"fa fa-lock\"></span>");
}
buf.push("</a><a" + (jade.attr("title", "" + (t('tooltip edit')) + "", true, false)) + " class=\"file-edit\"><span class=\"glyphicon glyphicon-edit\"></span></a><a" + (jade.attr("title", "" + (t('tooltip move')) + "", true, false)) + " class=\"file-move\"><span class=\"glyphicon glyphicon-arrow-right\"></span></a><a" + (jade.attr("title", "" + (t('tooltip delete')) + "", true, false)) + " class=\"file-delete\"><span class=\"glyphicon glyphicon-remove-circle\"></span></a><a" + (jade.attr("href", "folders/" + (model.id) + "/zip/" + (model.name) + "", true, false)) + " target=\"_blank\"" + (jade.attr("title", "" + (t('tooltip download')) + "", true, false)) + " class=\"file-download\"><span class=\"glyphicon glyphicon-cloud-download\"></span></a></div></div><p class=\"file-path\">" + (jade.escape((jade_interp = model.path) == null ? '' : jade_interp)) + "/" + (jade.escape((jade_interp = model.name) == null ? '' : jade_interp)) + "</p></td><td class=\"size-column-cell\">");
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
buf.push("<table id=\"table-items\" class=\"table table-hover\"><thead><tr class=\"table-headers\"><td><span>" + (jade.escape(null == (jade_interp = t('name')) ? "" : jade_interp)) + "</span><a id=\"down-name\" class=\"btn glyphicon glyphicon-chevron-down unactive\"></a><a id=\"up-name\" class=\"btn glyphicon glyphicon-chevron-up unactive\"></a></td><td class=\"size-column-cell\"><span>" + (jade.escape(null == (jade_interp = t('size')) ? "" : jade_interp)) + "</span><a id=\"down-size\" class=\"glyphicon glyphicon-chevron-down btn unactive\"></a><a id=\"up-size\" class=\"unactive btn glyphicon glyphicon-chevron-up unactive\"></a></td><td class=\"type-column-cell\"><span>" + (jade.escape(null == (jade_interp = t('type')) ? "" : jade_interp)) + "</span><a id=\"down-class\" class=\"btn glyphicon glyphicon-chevron-down unactive\"></a><a id=\"up-class\" class=\"glyphicon glyphicon-chevron-up btn unactive\"></a></td><td class=\"date-column-cell\"><span>" + (jade.escape(null == (jade_interp = t('date')) ? "" : jade_interp)) + "</span><a id=\"down-lastModification\" class=\"btn glyphicon glyphicon-chevron-down unactive\"></a><a id=\"up-lastModification\" class=\"btn glyphicon glyphicon-chevron-up unactive\"></a></td></tr></thead><tbody id=\"table-items-body\"></tbody></table><p id=\"file-amount-indicator\" class=\"footer\"></p><p id=\"no-files-indicator\" class=\"footer\">");
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
var locals_ = (locals || {}),query = locals_.query,model = locals_.model;
buf.push("<div id=\"affixbar\" data-spy=\"affix\" data-offset-top=\"1\"><div class=\"container\"><div class=\"row\"><div class=\"col-lg-12\"><div id=\"crumbs\" class=\"pull-left\"></div><p class=\"pull-right\"><input id=\"search-box\" type=\"search\"" + (jade.attr("value", "" + (query) + "", true, false)) + "/>");
if ( model.type != 'search')
{
buf.push("<div id=\"upload-buttons\" class=\"pull-right\">");
if ( model.id != 'root')
{
buf.push("<a id=\"share-state\" class=\"btn btn-cozy btn-cozy-contrast\">");
if ( model.clearance == 'public')
{
buf.push("" + (jade.escape((jade_interp = t('public')) == null ? '' : jade_interp)) + "<span class=\"fa fa-globe\"></span>");
}
else if ( model.clearance && model.clearance.length > 0)
{
buf.push("" + (jade.escape((jade_interp = t('shared')) == null ? '' : jade_interp)) + "<span class=\"fa fa-users\"></span><span>" + (jade.escape(null == (jade_interp = model.clearance.length) ? "" : jade_interp)) + "</span>");
}
else
{
buf.push("" + (jade.escape((jade_interp = t('private')) == null ? '' : jade_interp)) + "<span class=\"fa fa-lock\"></span>");
}
buf.push("</a>&nbsp;");
}
buf.push("<a id=\"button-upload-new-file\"" + (jade.attr("title", t('upload button'), true, false)) + " class=\"btn btn-cozy btn-cozy\"><img src=\"images/add-file.png\"/></a>&nbsp;<a id=\"button-new-folder\"" + (jade.attr("title", t('new folder button'), true, false)) + " class=\"btn btn-cozy\"><img src=\"images/add-folder.png\"/></a>&nbsp;<span>&nbsp;</span></div>");
}
buf.push("</p></div></div></div></div><div class=\"container\"><div class=\"row\"><div id=\"content\" class=\"col-lg-12\"><div id=\"loading-indicator\">&nbsp;</div><div id=\"files\"></div><div id=\"files-drop-zone\"><div class=\"overlay\"></div><div class=\"vertical-container\"><p>" + (jade.escape(null == (jade_interp = t('drop message')) ? "" : jade_interp)) + "</p></div></div></div></div></div>");;return buf.join("");
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

;require.register("views/templates/modal_upload", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<div class=\"modal-dialog\"><div class=\"modal-content\"><div class=\"modal-header\"><button type=\"button\" data-dismiss=\"modal\" aria-hidden=\"true\" class=\"close\">×</button><h4 class=\"modal-title\">" + (jade.escape((jade_interp = t("upload caption")) == null ? '' : jade_interp)) + "</h4></div><div class=\"modal-body\"><fieldset><div class=\"form-group\"><div id=\"uploader\"><div class=\"text\">" + (jade.escape((jade_interp = t("upload msg")) == null ? '' : jade_interp)) + "</div><input type=\"file\" multiple=\"multiple\"/></div></div></fieldset><div id=\"progress-total\"></div><div id=\"progress-part\"></div></div><div class=\"modal-footer\"><button id=\"modal-dialog-no\" type=\"button\" data-dismiss=\"modal\" class=\"btn btn-link\">" + (jade.escape((jade_interp = t("upload close")) == null ? '' : jade_interp)) + "</button><button id=\"modal-dialog-yes\" type=\"button\" disabled=\"disabled\" class=\"btn btn-cozy-contrast\">" + (jade.escape((jade_interp = t("upload send")) == null ? '' : jade_interp)) + "</button></div></div></div>");;return buf.join("");
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
    return this.render();
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

;
//# sourceMappingURL=app.js.map