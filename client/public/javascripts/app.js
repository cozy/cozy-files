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
      isFolder: true
    });
    this.folderView = new FolderView(this.root, this.breadcrumbs);
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
var BreadcrumbsManager, File, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

File = require('../models/file');

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
    var found, treatment,
      _this = this;
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
  };

  BreadcrumbsManager.prototype.setRoot = function(root) {
    this.reset();
    return this.add(root);
  };

  return BreadcrumbsManager;

})(Backbone.Collection);

});

;require.register("collections/files", function(exports, require, module) {
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

  FileCollection.prototype.sync = function(method, model, options) {
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

  FileCollection.prototype.comparator = function(o1, o2) {
    var n1, n2, sort, t1, t2;
    n1 = o1.get("name").toLocaleLowerCase();
    n2 = o2.get("name").toLocaleLowerCase();
    t1 = o1.get("isFolder");
    t2 = o2.get("isFolder");
    sort = this.order === "asc" ? -1 : 1;
    if (t1 === t2) {
      if (n1 > n2) {
        return -sort;
      }
      if (n1 < n2) {
        return sort;
      }
      return 0;
    } else if (t1) {
      return -1;
    } else {
      return 1;
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

;require.register("initialize", function(exports, require, module) {
var app;

app = require('application');

$(function() {
  jQuery.event.props.push('dataTransfer');
  app.initialize();
  return $.fn.spin = function(opts, color) {
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
});

});

;require.register("lib/app_helpers", function(exports, require, module) {
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

;require.register("lib/base_view", function(exports, require, module) {
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

;require.register("lib/view_collection", function(exports, require, module) {
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

;require.register("models/file", function(exports, require, module) {
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

  File.prototype.urlRoot = function() {
    if (this.get("isFolder")) {
      return 'folders/';
    } else {
      return 'files/';
    }
  };

  File.prototype.validate = function(attrs, options) {
    var errors;
    errors = [];
    if (!attrs.name || attrs.name === "") {
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

  File.prototype.find = function(callbacks) {
    this.prepareCallbacks(callbacks);
    return client.get("folders/" + this.id, callbacks);
  };

  File.prototype.findFiles = function(callbacks) {
    this.prepareCallbacks(callbacks);
    return client.get("folders/" + this.id + "/files", callbacks);
  };

  File.prototype.findFolders = function(callbacks) {
    this.prepareCallbacks(callbacks);
    return client.get("folders/" + this.id + "/folders", callbacks);
  };

  File.prototype.getAttachment = function(file, callbacks) {
    this.prepareCallbacks(callbacks);
    return client.post("files/" + this.id + "/getAttachment/" + this.name, callbacks);
  };

  return File;

})(Backbone.Model);

});

;require.register("router", function(exports, require, module) {
var File, FolderView, MockupView, Router, app, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

app = require('application');

FolderView = require('./views/folder');

MockupView = require('./views/mockup');

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
    'mockup': 'mockup'
  };

  Router.prototype.main = function() {
    return app.folderView.changeActiveFolder(app.root);
  };

  Router.prototype.folder = function(id) {
    var folder,
      _this = this;
    folder = new File({
      id: id,
      isFolder: true
    });
    return folder.find({
      success: function(data) {
        folder.set(data);
        return app.folderView.changeActiveFolder(folder);
      }
    });
  };

  Router.prototype.mockup = function() {
    if (this.displayedView) {
      this.displayedView.remove();
    }
    this.displayedView = new MockupView();
    return this.displayedView.render();
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

;require.register("views/file", function(exports, require, module) {
var BaseView, FileView, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

module.exports = FileView = (function(_super) {
  __extends(FileView, _super);

  function FileView() {
    _ref = FileView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  FileView.prototype.className = 'folder-row';

  FileView.prototype.tagName = 'tr';

  FileView.prototype.template = require('./templates/file');

  FileView.prototype.events = {
    'click a.file-delete': 'onDeleteClicked'
  };

  FileView.prototype.initialize = function() {
    return this.listenTo(this.model, 'change:id', this.render);
  };

  FileView.prototype.onDeleteClicked = function() {
    if (confirm('Are you sure ?')) {
      return this.model.destroy({
        error: function() {
          return alert("Server error occured, file was not deleted.");
        }
      });
    }
  };

  return FileView;

})(BaseView);

});

;require.register("views/files", function(exports, require, module) {
var File, FileCollection, FileView, FilesView, ViewCollection, _ref,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

ViewCollection = require('../lib/view_collection');

FileView = require('./file');

File = require('../models/file');

FileCollection = require('../collections/files');

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
    return this.listenTo(this.collection, "sort", this.render);
  };

  FilesView.prototype.afterRender = function() {
    return FilesView.__super__.afterRender.call(this);
  };

  FilesView.prototype.addFile = function(attach) {
    var file, fileAttributes, found, _i, _len, _ref1;
    found = false;
    _ref1 = this.collection.models;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      file = _ref1[_i];
      if (file.get("name") === attach.name) {
        found = true;
      }
    }
    if (!found) {
      fileAttributes = {
        name: attach.name,
        path: this.model.repository()
      };
      file = new File(fileAttributes);
      file.file = attach;
      this.collection.add(file);
      return this.upload(file);
    } else {
      return alert("Sorry, could not upload the file: it already exists");
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
    return Backbone.sync('create', file, {
      contentType: false,
      data: formdata,
      success: function(data) {
        return file.set(data);
      }
    });
  };

  FilesView.prototype.addFolder = function(folder) {
    var _this = this;
    return this.collection.create(folder, {
      success: function(data) {},
      error: function(error) {
        _this.collection.reset(folder);
        return alert(error.msg);
      }
    });
  };

  return FilesView;

})(ViewCollection);

});

;require.register("views/folder", function(exports, require, module) {
var BaseView, BreadcrumbsView, File, FileCollection, FilesView, FolderView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

FilesView = require('./files');

BreadcrumbsView = require("./breadcrumbs");

File = require('../models/file');

FileCollection = require('../collections/files');

module.exports = FolderView = (function(_super) {
  __extends(FolderView, _super);

  FolderView.prototype.template = require('./templates/folder');

  FolderView.prototype.events = function() {
    return {
      'click #new-folder-send': 'onAddFolder',
      'click #upload-file-send': 'onAddFile'
    };
  };

  function FolderView(model, breadcrumbs) {
    this.model = model;
    this.breadcrumbs = breadcrumbs;
    this.onAddFile = __bind(this.onAddFile, this);
    this.onAddFolder = __bind(this.onAddFolder, this);
    FolderView.__super__.constructor.call(this);
    this.breadcrumbs.setRoot(this.model);
  }

  FolderView.prototype.render = function() {
    this.beforeRender();
    this.$el.html(this.template({
      model: this.model
    }));
    this.afterRender();
    return this;
  };

  FolderView.prototype.afterRender = function() {
    FolderView.__super__.afterRender.call(this);
    this.breadcrumbsView = new BreadcrumbsView(this.breadcrumbs);
    return this.$("#crumbs").append(this.breadcrumbsView.render().$el);
  };

  FolderView.prototype.changeActiveFolder = function(folder) {
    this.model = folder;
    this.breadcrumbs.push(folder);
    return this.displayChildren();
  };

  FolderView.prototype.displayChildren = function() {
    var _this = this;
    return this.model.findFiles({
      success: function(files) {
        return _this.model.findFolders({
          success: function(folders) {
            var folder, _i, _len;
            for (_i = 0, _len = folders.length; _i < _len; _i++) {
              folder = folders[_i];
              folder.isFolder = true;
            }
            _this.filesCollection = new FileCollection(files.concat(folders));
            _this.filesList = new FilesView(_this.filesCollection, _this.model);
            _this.$('#files').html(_this.filesList.$el);
            return _this.filesList.render();
          },
          error: function(error) {
            return console.log(error);
          }
        });
      },
      error: function(error) {
        return console.log(error);
      }
    });
  };

  FolderView.prototype.onAddFolder = function() {
    var err, folder;
    folder = {
      name: this.$('#inputName').val(),
      path: this.model.repository(),
      isFolder: true
    };
    folder = new File(folder);
    err = folder.validate(folder.attributes);
    if (err) {
      return alert("The folder name is empty");
    } else {
      this.filesList.addFolder(folder.attributes);
      return $('#dialog-new-folder').modal('hide');
    }
  };

  FolderView.prototype.onAddFile = function() {
    var attach, _i, _len, _ref;
    _ref = this.$('#uploader')[0].files;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      attach = _ref[_i];
      this.filesList.addFile(attach);
    }
    return $('#dialog-upload-file').modal('hide');
  };

  return FolderView;

})(BaseView);

});

;require.register("views/mockup", function(exports, require, module) {
var BaseView, MockupView, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

module.exports = MockupView = (function(_super) {
  __extends(MockupView, _super);

  function MockupView() {
    _ref = MockupView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  MockupView.prototype.template = require('./templates/mockup');

  MockupView.prototype.el = "body";

  return MockupView;

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
buf.push('<li><a href="#"><span class="glyphicon glyphicon-folder-open"></span></a></li>');
}
else
{
buf.push('<li><a');
buf.push(attrs({ 'href':("#folders/" + (model.id) + "") }, {"href":true}));
buf.push('>' + escape((interp = model.attributes.name) == null ? '' : interp) + '</a></li>');
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
if ( model.isFolder)
{
buf.push('<td><span class="glyphicon glyphicon-folder-close"> </span><a');
buf.push(attrs({ 'href':("#folders/" + (model.id) + ""), "class": ('btn') + ' ' + ('btn-linka') }, {"href":true}));
buf.push('>' + escape((interp = model.name) == null ? '' : interp) + '</a><div class="operations"><a class="file-delete"><span class="glyphicon glyphicon-remove-circle"> </span></a><a class="file-edit"><span class="glyphicon glyphicon-edit"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td>');
}
else
{
buf.push('<td><span class="glyphicon glyphicon-file"> </span><a');
buf.push(attrs({ 'href':("files/" + (model.id) + "/attach/" + (model.name) + ""), 'target':("_blank"), "class": ('btn') + ' ' + ('btn-linka') }, {"href":true,"target":true}));
buf.push('>' + escape((interp = model.name) == null ? '' : interp) + '</a><div class="operations"><a class="file-delete"><span class="glyphicon glyphicon-remove-circle"> </span></a><a class="file-edit"><span class="glyphicon glyphicon-edit"> </span></a><a');
buf.push(attrs({ 'href':("files/" + (model.id) + "/download/" + (model.name) + ""), 'download':("" + (model.name) + "") }, {"href":true,"download":true}));
buf.push('><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td>');
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
buf.push('<div id="dialog-upload-file" class="modal fade"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button><h4 class="modal-title">Upload a new file</h4></div><div class="modal-body"><form><fieldset><div class="form-group"><label for="uploader">Choose the file to upload:</label><input id="uploader" type="file" class="form-control"/></div></fieldset></form></div><div class="modal-footer"><button type="button" data-dismiss="modal" class="btn btn-link">Close</button><button id="upload-file-send" type="button" class="btn btn-cozy-contrast">Send</button></div></div></div></div><div id="dialog-new-folder" class="modal fade"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button><h4 class="modal-title">Add a new folder</h4></div><div class="modal-body"><form><fieldset><div class="form-group"><label for="inputName">Enter the folder\'s name: </label><input id="inputName" type="text" class="form-control"/></div></fieldset></form></div><div class="modal-footer"><button type="button" data-dismiss="modal" class="btn btn-link">Close</button><button id="new-folder-send" type="button" class="btn btn-cozy">Send</button></div></div></div></div><div id="affixbar" data-spy="affix" data-offset-top="1"><div class="container"><div class="row"><div class="col-lg-12"><p class="pull-right"><a data-toggle="modal" data-target="#dialog-upload-file" class="btn btn-cozy-contrast"><span class="glyphicon glyphicon-upload"></span>');
if ( model.id == "root")
{
buf.push(' Upload a file here');
}
else
{
buf.push(' Upload a file to "' + escape((interp = model.get("name")) == null ? '' : interp) + '"');
}
buf.push('</a> <a data-toggle="modal" data-target="#dialog-new-folder" class="btn btn-cozy"><span class="glyphicon glyphicon-plus-sign"></span> Create a new folder</a></p></div></div></div></div><div class="container"><div class="row content-shadow"><div id="content" class="col-lg-12"><div id="crumbs"></div><div id="files"></div></div></div></div>');
}
return buf.join("");
};
});

;require.register("views/templates/mockup", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div id="dialog-upload-file" class="modal fade"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button><h4 class="modal-title">Upload a new file</h4></div><div class="modal-body"><form><fieldset><div class="form-group"><label for="uploader">Choose the file to upload:</label><input id="uploader" type="file" class="form-control"/></div></fieldset></form></div><div class="modal-footer"><button type="button" data-dismiss="modal" class="btn btn-link">Close</button><button type="button" class="btn btn-cozy-contrast">Send</button></div></div></div></div><div id="dialog-new-folder" class="modal fade"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><button type="button" data-dismiss="modal" aria-hidden="true" class="close">×</button><h4 class="modal-title">Add a new folder</h4></div><div class="modal-body"><form><fieldset><div class="form-group"><label for="inputName">Enter the folder\'s name: </label><input id="inputName" type="text" class="form-control"/></div></fieldset></form></div><div class="modal-footer"><button type="button" data-dismiss="modal" class="btn btn-link">Close</button><button type="button" class="btn btn-cozy">Send</button></div></div></div></div><div id="affixbar" data-spy="affix" data-offset-top="1"><div class="container"><div class="row"><div class="col-lg-12"><p class="pull-right"><a href="#dialog-upload-file" data-toggle="modal" data-target="#dialog-upload-file" class="btn btn-cozy-contrast"><span class="glyphicon glyphicon-upload"></span> Upload a file to "silly cats"</a> <a href="#dialog-new-folder" data-toggle="modal" data-target="#dialog-new-folder" class="btn btn-cozy"><span class="glyphicon glyphicon-plus-sign"></span> Create a new folder</a></p></div></div></div></div><div class="container"><div class="row content-shadow"><div id="content" class="col-lg-12"><div id="crumbs"><ul><li><a href="#"><span class="glyphicon glyphicon-folder-open"> </span></a></li><li><a href="#">personal</a></li><li><a href="#">photos</a></li><li><a href="#">very long folder name it is indeed</a></li><li><a href="#">another one</a></li><li><a href="#">silly cats</a></li></ul></div><table id="table-items" class="table table-hover"><tbody><tr class="folder-row"><td><span class="glyphicon glyphicon-folder-close"> </span><a class="btn btn-link">little grumpy cat</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-folder-close"> </span><a class="btn btn-link">little grumpy cat</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-folder-close"> </span><a class="btn btn-link">little grumpy cat</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-folder-close"> </span><a class="btn btn-link">little grumpy cat</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">sweet kitty on a bicycle.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">sweet kitty on a bicycle.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">sweet kitty on a bicycle.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">sweet kitty on a bicycle.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">sweet kitty on a bicycle.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">sweet kitty on a bicycle.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">sweet kitty on a bicycle.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">super sweet kitty.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">super sweet kitty.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">super sweet kitty.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">super sweet kitty.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">super sweet kitty.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">super sweet kitty.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">super sweet kitty.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">super sweet kitty.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">super sweet kitty.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">super sweet kitty.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr><tr class="folder-row"><td><span class="glyphicon glyphicon-file"> </span><a class="btn btn-link">super sweet kitty.jpg</a><div class="operations"><a><span class="glyphicon glyphicon-remove-circle"> </span></a><a><span class="glyphicon glyphicon-edit"> </span></a><a><span class="glyphicon glyphicon-cloud-download"> </span></a></div></td><td class="operation-title"></td><td class="operation-amount"><span class="pull-right">12:00 12/10/2013</span></td></tr></tbody></table></div></div></div>');
}
return buf.join("");
};
});

;
//# sourceMappingURL=app.js.map