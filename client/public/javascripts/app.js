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
  module.exports = {
    initialize: function() {
      var ContactsCollection, ContactsList, Router;
      ContactsCollection = require('collections/contact');
      ContactsList = require('views/contactslist');
      Router = require('router');
      this.contacts = new ContactsCollection();
      this.contactslist = new ContactsList({
        collection: this.contacts
      });
      this.contactslist.render();
      this.contactslist.$el.appendTo($('body'));
      this.router = new Router();
      return Backbone.history.start();
    }
  };
  
});
window.require.register("collections/contact", function(exports, require, module) {
  var ContactCollection, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = ContactCollection = (function(_super) {
    __extends(ContactCollection, _super);

    function ContactCollection() {
      _ref = ContactCollection.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ContactCollection.prototype.model = require('models/contact');

    ContactCollection.prototype.url = 'contacts';

    ContactCollection.prototype.comparator = 'name';

    ContactCollection.prototype.initialize = function() {
      var _this = this;
      ContactCollection.__super__.initialize.apply(this, arguments);
      return this.on('change:name', function() {
        return _this.sort();
      });
    };

    return ContactCollection;

  })(Backbone.Collection);
  
});
window.require.register("collections/datapoint", function(exports, require, module) {
  var DataPointCollection, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = DataPointCollection = (function(_super) {
    __extends(DataPointCollection, _super);

    function DataPointCollection() {
      _ref = DataPointCollection.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    DataPointCollection.prototype.model = require('models/datapoint');

    DataPointCollection.prototype.hasOne = function(type) {
      return this.where({
        name: type
      }).length > 0;
    };

    DataPointCollection.prototype.prune = function() {
      var toDelete,
        _this = this;
      toDelete = [];
      this.each(function(datapoint) {
        var value;
        value = datapoint.get('value');
        if ((value === null) || (value === '') || (value === ' ')) {
          return toDelete.push(datapoint);
        }
      });
      return this.remove(toDelete);
    };

    DataPointCollection.prototype.match = function(filter) {
      return this.any(function(datapoint) {
        return filter.test(datapoint.get('value'));
      });
    };

    return DataPointCollection;

  })(Backbone.Collection);
  
});
window.require.register("initialize", function(exports, require, module) {
  var app;

  app = require('application');

  $(function() {
    jQuery.event.props.push('dataTransfer');
    return app.initialize();
  });
  
});
window.require.register("lib/base_view", function(exports, require, module) {
  var BaseView, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = BaseView = (function(_super) {
    __extends(BaseView, _super);

    function BaseView() {
      this.render = __bind(this.render, this);
      _ref = BaseView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    BaseView.prototype.initialize = function(options) {
      return this.options = options;
    };

    BaseView.prototype.template = function() {};

    BaseView.prototype.getRenderData = function() {};

    BaseView.prototype.render = function() {
      var data;
      data = _.extend({}, this.options, this.getRenderData());
      this.$el.html(this.template(data));
      this.afterRender();
      return this;
    };

    BaseView.prototype.afterRender = function() {};

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

    ViewCollection.prototype.views = {};

    ViewCollection.prototype.itemView = null;

    ViewCollection.prototype.itemViewOptions = function() {};

    ViewCollection.prototype.checkIfEmpty = function() {
      return this.$el.toggleClass('empty', _.size(this.views) === 0);
    };

    ViewCollection.prototype.appendView = function(view) {
      return this.$el.append(view.el);
    };

    ViewCollection.prototype.initialize = function() {
      ViewCollection.__super__.initialize.apply(this, arguments);
      this.views = {};
      this.listenTo(this.collection, "reset", this.onReset);
      this.listenTo(this.collection, "add", this.addItem);
      this.listenTo(this.collection, "remove", this.removeItem);
      this.listenTo(this.collection, "sort", this.onReset);
      return this.onReset(this.collection);
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
      _ref1 = this.views;
      for (id in _ref1) {
        view = _ref1[id];
        this.appendView(view);
      }
      return this.checkIfEmpty(this.views);
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
      view = new this.itemView(options);
      this.views[model.cid] = view.render();
      this.appendView(view);
      return this.checkIfEmpty(this.views);
    };

    ViewCollection.prototype.removeItem = function(model) {
      this.views[model.cid].remove();
      delete this.views[model.cid];
      return this.checkIfEmpty(this.views);
    };

    return ViewCollection;

  })(BaseView);
  
});
window.require.register("models/contact", function(exports, require, module) {
  var Contact, DataPoint, DataPointCollection,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  DataPoint = require('models/datapoint');

  DataPointCollection = require('collections/datapoint');

  module.exports = Contact = (function(_super) {
    __extends(Contact, _super);

    Contact.prototype.urlRoot = 'contacts';

    function Contact() {
      this.match = __bind(this.match, this);
      this.addDP = __bind(this.addDP, this);
      this.dataPoints = new DataPointCollection();
      Contact.__super__.constructor.apply(this, arguments);
    }

    Contact.prototype.defaults = function() {
      return {
        fn: '',
        note: ''
      };
    };

    Contact.prototype.parse = function(attrs) {
      if (attrs.datapoints) {
        this.dataPoints.reset(attrs.datapoints);
        delete attrs.datapoints;
      }
      return attrs;
    };

    Contact.prototype.sync = function(method, model, options) {
      var success,
        _this = this;
      if (this.picture) {
        options.contentType = false;
        options.data = new FormData();
        options.data.append('picture', this.picture);
        options.data.append('contact', JSON.stringify(this.toJSON()));
        success = options.success;
        options.success = function(resp) {
          success(resp);
          _this.trigger('change', _this, {});
          return delete _this.picture;
        };
      }
      return Contact.__super__.sync.call(this, method, model, options);
    };

    Contact.prototype.addDP = function(name, type, value) {
      return this.dataPoints.add({
        type: type,
        name: name,
        value: value
      });
    };

    Contact.prototype.match = function(filter) {
      return filter.test(this.get('fn')) || filter.test(this.get('note')) || this.dataPoints.match(filter);
    };

    Contact.prototype.toJSON = function() {
      var json;
      json = Contact.__super__.toJSON.apply(this, arguments);
      json.datapoints = this.dataPoints.toJSON();
      delete json.picture;
      return json;
    };

    return Contact;

  })(Backbone.Model);

  Contact.fromVCF = function(vcf) {
    var ContactCollection, all, current, currentdp, currentidx, currentversion, imported, itemidx, key, line, part, pname, properties, property, pvalue, regexps, value, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
    regexps = {
      begin: /^BEGIN:VCARD$/i,
      end: /^END:VCARD$/i,
      simple: /^(version|fn|title|org|note)\:(.+)$/i,
      composedkey: /^item(\d{1,2})\.([^\:]+):(.+)$/,
      complex: /^([^\:\;]+);([^\:]+)\:(.+)$/,
      property: /^(.+)=(.+)$/
    };
    ContactCollection = require('collections/contact');
    imported = new ContactCollection();
    currentversion = "3.0";
    current = null;
    currentidx = null;
    currentdp = null;
    _ref = vcf.split(/\r?\n/);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      line = _ref[_i];
      if (regexps.begin.test(line)) {
        current = new Contact();
      } else if (regexps.end.test(line)) {
        if (currentdp) {
          current.dataPoints.add(currentdp);
        }
        imported.add(current);
        currentdp = null;
        current = null;
        currentidx = null;
        currentversion = "3.0";
      } else if (regexps.simple.test(line)) {
        _ref1 = line.match(regexps.simple), all = _ref1[0], key = _ref1[1], value = _ref1[2];
        key = key.toLowerCase();
        switch (key) {
          case 'version':
            currentversion = value;
            break;
          case 'title':
          case 'org':
            current.addDP('about', key, value);
            break;
          case 'fn':
          case 'note':
            current.set(key, value);
        }
      } else if (regexps.composedkey.test(line)) {
        _ref2 = line.match(regexps.composedkey), all = _ref2[0], itemidx = _ref2[1], part = _ref2[2], value = _ref2[3];
        if (currentidx === null || currentidx !== itemidx) {
          if (currentdp) {
            current.dataPoints.add(currentdp);
          }
          currentdp = new DataPoint();
        }
        currentidx = itemidx;
        part = part.split(';');
        key = part[0];
        properties = part.splice(1);
        value = value.split(';');
        if (value.length === 1) {
          value = value[0];
        }
        key = key.toLowerCase();
        if (key === 'x-ablabel' || key === 'x-abadr') {
          currentdp.set('type', value.toLowerCase());
        } else {
          for (_j = 0, _len1 = properties.length; _j < _len1; _j++) {
            property = properties[_j];
            _ref3 = property.match(regexps.property), all = _ref3[0], pname = _ref3[1], pvalue = _ref3[2];
            currentdp.set(pname.toLowerCase(), pvalue.toLowerCase());
          }
          if (key === 'adr') {
            value = value.join("\n").replace(/\n+/g, "\n");
          }
          currentdp.set('name', key.toLowerCase());
          currentdp.set('value', value.replace("\\:", ":"));
        }
      } else if (regexps.complex.test(line)) {
        _ref4 = line.match(regexps.complex), all = _ref4[0], key = _ref4[1], properties = _ref4[2], value = _ref4[3];
        if (currentdp) {
          current.dataPoints.add(currentdp);
        }
        currentdp = new DataPoint();
        value = value.split(';');
        if (value.length === 1) {
          value = value[0];
        }
        key = key.toLowerCase();
        if (key === 'email' || key === 'tel' || key === 'adr' || key === 'url') {
          currentdp.set('name', key);
          if (key === 'adr') {
            value = value.join("\n").replace(/\n+/g, "\n");
          }
        } else {
          currentdp = null;
          continue;
        }
        properties = properties.split(';');
        for (_k = 0, _len2 = properties.length; _k < _len2; _k++) {
          property = properties[_k];
          _ref5 = property.match(regexps.property), all = _ref5[0], pname = _ref5[1], pvalue = _ref5[2];
          if (pname === 'type' && pvalue === 'pref') {
            currentdp.set('pref', 1);
          } else {
            currentdp.set(pname.toLowerCase(), pvalue.toLowerCase());
          }
        }
        currentdp.set('value', value);
      }
    }
    return imported;
  };
  
});
window.require.register("models/datapoint", function(exports, require, module) {
  var DataPoint, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = DataPoint = (function(_super) {
    __extends(DataPoint, _super);

    function DataPoint() {
      _ref = DataPoint.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    DataPoint.prototype.defaults = {
      type: 'main',
      name: 'other',
      value: ''
    };

    return DataPoint;

  })(Backbone.Model);
  
});
window.require.register("router", function(exports, require, module) {
  var Contact, ContactView, HelpView, ImporterView, Router, app, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  app = require('application');

  ContactView = require('views/contact');

  HelpView = require('views/help');

  ImporterView = require('views/importer');

  Contact = require('models/contact');

  module.exports = Router = (function(_super) {
    __extends(Router, _super);

    function Router() {
      _ref = Router.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Router.prototype.routes = {
      '': 'help',
      'import': 'import',
      'contact/new': 'newcontact',
      'contact/:id': 'showcontact'
    };

    Router.prototype.initialize = function() {
      var _this = this;
      return $('body').on('keyup', function(e) {
        if (event.keyCode === 27) {
          return _this.navigate("", true);
        }
      });
    };

    Router.prototype.help = function() {
      return this.displayView(new HelpView());
    };

    Router.prototype["import"] = function() {
      this.help();
      this.importer = new ImporterView();
      return $('body').append(this.importer.render().$el);
    };

    Router.prototype.newcontact = function() {
      var contact,
        _this = this;
      contact = new Contact();
      contact.once('change:id', function() {
        app.contacts.add(contact);
        return _this.navigate("contact/" + contact.id, false);
      });
      this.displayViewFor(contact);
      return $('#name').focus();
    };

    Router.prototype.showcontact = function(id) {
      var contact,
        _this = this;
      if (app.contacts.length === 0) {
        app.contacts.once('sync', function() {
          return _this.showcontact(id);
        });
        return;
      }
      contact = app.contacts.get(id);
      if (contact) {
        return this.displayViewFor(contact);
      } else {
        alert("this contact doesn't exist");
        return this.navigate('', true);
      }
    };

    Router.prototype.displayView = function(view) {
      var _ref1,
        _this = this;
      if (this.currentContact) {
        this.stopListening(this.currentContact);
      }
      if ((_ref1 = app.contactview) != null ? _ref1.needSaving : void 0) {
        app.contactview.save();
        app.contactview.once('sync', function() {
          return _this.displayView(view);
        });
        return;
      }
      if (this.importer) {
        this.importer.close();
      }
      this.importer = null;
      if (app.contactview) {
        app.contactview.remove();
      }
      app.contactview = view;
      app.contactview.render();
      return app.contactview.$el.appendTo($('body'));
    };

    Router.prototype.displayViewFor = function(contact) {
      this.currentContact = contact;
      this.displayView(new ContactView({
        model: contact
      }));
      return this.listenTo(contact, 'destroy', function() {
        return this.navigate('', true);
      });
    };

    return Router;

  })(Backbone.Router);
  
});
window.require.register("templates/contact", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<div id="spinOverlay"><span>saving ...</span></div><input');
  buf.push(attrs({ 'id':('name'), 'placeholder':("Name"), 'value':("" + (fn) + "") }, {"placeholder":true,"value":true}));
  buf.push('/><div id="picture">');
  if ( typeof(id) != 'undefined')
  {
  buf.push('<img');
  buf.push(attrs({ 'src':("contacts/" + (id) + "/picture.png"), "class": ('picture') }, {"src":true}));
  buf.push('/>');
  }
  else
  {
  buf.push('<img src="img/defaultpicture.png" class="picture"/>');
  }
  buf.push('<div id="uploadnotice">Change</div><input id="uploader" type="file"/></div><a id="close" href="#">&times;</a><textarea rows="3" placeholder="Take notes here" id="notes">' + escape((interp = note) == null ? '' : interp) + '</textarea><div id="commands"><a id="save" class="btn">  Save</a><a id="delete" class="btn">Delete</a><div class="btn-group"><a data-toggle="dropdown" href="#" class="btn dropdown-toggle">Add<span class="caret"></span></a><ul class="dropdown-menu pull-right"><li><a class="addbirthday">Birthday</a></li><li><a class="addcompany">Company</a></li><li><a class="addtitle">Title</a></li><li class="divider"></li><li><a class="addtel">  Phone</a></li><li><a class="addemail">Email</a></li><li><a class="addadr">  Postal</a></li><li><a class="addurl">  Url</a></li><li><a class="addother">Other</a></li></ul></div></div><div id="abouts" class="zone"><h2>About<a class="btn add addabout"><i class="icon-plus"></i></a></h2><ul></ul></div><div id="tels" class="zone"><h2>Phones<a class="btn add addtel"><i class="icon-plus"></i></a></h2><ul></ul></div><div id="emails" class="zone"><h2>Emails<a class="btn add addemail"><i class="icon-plus"></i></a></h2><ul></ul></div><div id="adrs" class="zone"><h2>Postal<a class="btn add addadr"><i class="icon-plus"></i></a></h2><ul></ul></div><div id="urls" class="zone"><h2>Links<a class="btn add addurl"><i class="icon-plus"></i></a></h2><ul></ul></div><div id="others" class="zone"><h2>Others<a class="btn add addother"><i class="icon-plus"></i></a></h2><ul></ul></div>');
  }
  return buf.join("");
  };
});
window.require.register("templates/contactslist", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<div id="toolbar"><input id="filterfield" type="text" placeholder="Search ..."/></div><div id="contacts"></div>');
  }
  return buf.join("");
  };
});
window.require.register("templates/contactslist_item", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<img');
  buf.push(attrs({ 'src':("contacts/" + (id) + "/picture.png") }, {"src":true}));
  buf.push('/><h2>' + escape((interp = fn) == null ? '' : interp) + '</h2>');
  }
  return buf.join("");
  };
});
window.require.register("templates/datapoint", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<input');
  buf.push(attrs({ 'type':("text"), 'data-provide':("typeahead"), 'value':("" + (type) + ""), "class": ('type') }, {"type":true,"data-provide":true,"value":true}));
  buf.push('/>');
  if ( name == 'adr')
  {
  buf.push('<textarea');
  buf.push(attrs({ 'rows':("4"), 'placeholder':("" + (placeholder) + ""), "class": ('value') }, {"rows":true,"placeholder":true}));
  buf.push('>' + escape((interp = value) == null ? '' : interp) + '</textarea>');
  }
  else
  {
  buf.push('<input');
  buf.push(attrs({ 'type':("text"), 'placeholder':("" + (placeholder) + ""), 'value':("" + (value) + ""), "class": ('value') }, {"type":true,"placeholder":true,"value":true}));
  buf.push('/>');
  }
  }
  return buf.join("");
  };
});
window.require.register("templates/help", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<a id="new" href="#contact/new">Create New Contact</a><a id="importvcf" href="#import">Import vCard</a><a id="exportvcf" href="contacts.vcf">Export vCard</a>');
  }
  return buf.join("");
  };
});
window.require.register("templates/importer", function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<div class="modal-header">Import vCard</div><div class="modal-body"><div class="control-group"><label for="vcfupload" class="control-label">Choose a vCard file</label><div class="controls"><input id="vcfupload" type="file"/><span class="help-inline"></span></div></div></div><div class="modal-footer"><a id="cancel-btn" href="#" class="btn">Cancel</a><a id="confirm-btn" class="btn disabled btn-primary">Import</a></div>');
  }
  return buf.join("");
  };
});
window.require.register("views/contact", function(exports, require, module) {
  var ContactView, Datapoint, ViewCollection,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ViewCollection = require('lib/view_collection');

  Datapoint = require('models/datapoint');

  module.exports = ContactView = (function(_super) {
    __extends(ContactView, _super);

    ContactView.prototype.id = 'contact';

    ContactView.prototype.template = require('templates/contact');

    ContactView.prototype.itemView = require('views/datapoint');

    ContactView.prototype.events = function() {
      return {
        'click .addbirthday': this.addClicked('about', 'birthday'),
        'click .addcompany': this.addClicked('about', 'org'),
        'click .addtitle': this.addClicked('about', 'title'),
        'click .addabout': this.addClicked('about'),
        'click .addtel': this.addClicked('tel'),
        'click .addemail': this.addClicked('email'),
        'click .addadr': this.addClicked('adr'),
        'click .addother': this.addClicked('other'),
        'click .addurl': this.addClicked('url'),
        'click #save': 'save',
        'click #delete': 'delete',
        'blur .value': 'cleanup',
        'keypress #name': 'changeOccured',
        'keypress #notes': 'changeOccured',
        'change #uploader': 'photoChanged'
      };
    };

    function ContactView(options) {
      this.photoChanged = __bind(this.photoChanged, this);
      this.save = __bind(this.save, this);
      options.collection = options.model.dataPoints;
      ContactView.__super__.constructor.apply(this, arguments);
    }

    ContactView.prototype.initialize = function() {
      ContactView.__super__.initialize.apply(this, arguments);
      this.listenTo(this.model, 'change', this.modelChanged);
      this.listenTo(this.model, 'destroy', this.modelDestroyed);
      this.listenTo(this.model, 'request', this.onRequest);
      this.listenTo(this.model, 'error', this.onError);
      this.listenTo(this.model, 'sync', this.onSuccess);
      return this.listenTo(this.collection, 'change', this.changeOccured);
    };

    ContactView.prototype.getRenderData = function() {
      return this.model.toJSON();
    };

    ContactView.prototype.afterRender = function() {
      var type, _i, _len, _ref;
      this.zones = {};
      _ref = ['about', 'email', 'adr', 'tel', 'url', 'other'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        type = _ref[_i];
        this.zones[type] = this.$('#' + type + 's ul');
      }
      this.hideEmptyZones();
      this.spinner = this.$('#spinOverlay');
      this.saveButton = this.$('#save').addClass('disabled').text('saved');
      this.needSaving = false;
      this.namefield = this.$('#name');
      this.notesfield = this.$('#notes');
      this.uploader = this.$('#uploader')[0];
      this.picture = this.$('#picture .picture');
      return ContactView.__super__.afterRender.apply(this, arguments);
    };

    ContactView.prototype.hideEmptyZones = function() {
      var type, zone, _ref, _results;
      _ref = this.zones;
      _results = [];
      for (type in _ref) {
        zone = _ref[type];
        _results.push(zone.parent().toggle(this.model.dataPoints.hasOne(type)));
      }
      return _results;
    };

    ContactView.prototype.appendView = function(dataPointView) {
      var type;
      if (!this.zones) {
        return;
      }
      type = dataPointView.model.get('name');
      this.zones[type].append(dataPointView.el);
      return this.hideEmptyZones();
    };

    ContactView.prototype.addClicked = function(name, type) {
      return function(event) {
        var point;
        event.preventDefault();
        point = new Datapoint({
          name: name
        });
        if (type != null) {
          point.set('type', type);
        }
        this.model.dataPoints.add(point);
        return this.zones[name].children().last().find('.type').focus();
      };
    };

    ContactView.prototype.changeOccured = function() {
      this.saveButton.removeClass('disabled').text('save');
      return this.needSaving = true;
    };

    ContactView.prototype.modelChanged = function() {
      this.namefield.val(this.model.get('fn'));
      return this.notesfield.val(this.model.get('note'));
    };

    ContactView.prototype["delete"] = function() {
      return this.model.destroy();
    };

    ContactView.prototype.cleanup = function() {
      this.model.dataPoints.prune();
      return this.hideEmptyZones();
    };

    ContactView.prototype.save = function() {
      if (!this.needSaving) {
        return;
      }
      this.cleanup();
      this.needSaving = false;
      return this.model.save({
        fn: this.namefield.val(),
        note: this.notesfield.val()
      });
    };

    ContactView.prototype.onRequest = function() {
      return this.spinner.show();
    };

    ContactView.prototype.onSuccess = function() {
      this.spinner.hide();
      return this.saveButton.addClass('disabled').text('saved');
    };

    ContactView.prototype.onError = function() {
      return this.spinner.hide();
    };

    ContactView.prototype.photoChanged = function() {
      var file, img, reader,
        _this = this;
      file = this.uploader.files[0];
      if (!file.type.match(/image\/.*/)) {
        return alert('This is not an image');
      }
      reader = new FileReader();
      img = new Image();
      reader.readAsDataURL(file);
      return reader.onloadend = function() {
        img.src = reader.result;
        return img.onload = function() {
          var array, binary, blob, canvas, ctx, dataUrl, i, ratio, ratiodim, _i, _ref;
          ratiodim = img.width > img.height ? 'height' : 'width';
          ratio = 64 / img[ratiodim];
          canvas = document.createElement('canvas');
          canvas.height = canvas.width = 64;
          ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0, ratio * img.width, ratio * img.height);
          dataUrl = canvas.toDataURL('image/jpeg');
          _this.picture.attr('src', dataUrl);
          binary = atob(dataUrl.split(',')[1]);
          array = [];
          for (i = _i = 0, _ref = binary.length; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
            array.push(binary.charCodeAt(i));
          }
          blob = new Blob([new Uint8Array(array)], {
            type: 'image/jpeg'
          });
          _this.model.picture = blob;
          return _this.changeOccured();
        };
      };
    };

    return ContactView;

  })(ViewCollection);
  
});
window.require.register("views/contactslist", function(exports, require, module) {
  var App, ContactsList, ViewCollection, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ViewCollection = require('lib/view_collection');

  App = require('application');

  module.exports = ContactsList = (function(_super) {
    __extends(ContactsList, _super);

    function ContactsList() {
      _ref = ContactsList.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ContactsList.prototype.id = 'contacts-list';

    ContactsList.prototype.itemView = require('views/contactslist_item');

    ContactsList.prototype.template = require('templates/contactslist');

    ContactsList.prototype.events = {
      'keyup #filterfield': 'keyUpCallback'
    };

    ContactsList.prototype.afterRender = function() {
      ContactsList.__super__.afterRender.apply(this, arguments);
      this.collection.fetch();
      this.list = this.$('#contacts');
      this.filterfield = this.$('#filterfield');
      return this.filterfield.focus();
    };

    ContactsList.prototype.appendView = function(view) {
      return this.list.append(view.$el);
    };

    ContactsList.prototype.keyUpCallback = function(event) {
      var firstmodel, id, match, view, _ref1;
      if (event.keyCode === 27) {
        this.filterfield.val('');
        App.router.navigate("", true);
      }
      this.filtertxt = this.filterfield.val();
      this.filtertxt = this.filtertxt.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
      this.filter = new RegExp(this.filtertxt, 'i');
      firstmodel = null;
      _ref1 = this.views;
      for (id in _ref1) {
        view = _ref1[id];
        match = (this.filtertxt === '') || view.model.match(this.filter);
        view.$el.toggle(match);
        if (match && !firstmodel) {
          firstmodel = view.model;
        }
      }
      if (firstmodel && event.keyCode === 13) {
        return App.router.navigate("contact/" + firstmodel.id, true);
      }
    };

    return ContactsList;

  })(ViewCollection);
  
});
window.require.register("views/contactslist_item", function(exports, require, module) {
  var BaseView, ContactsListItemView, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseView = require('lib/base_view');

  module.exports = ContactsListItemView = (function(_super) {
    __extends(ContactsListItemView, _super);

    function ContactsListItemView() {
      _ref = ContactsListItemView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ContactsListItemView.prototype.tagName = 'a';

    ContactsListItemView.prototype.className = 'contact-thumb';

    ContactsListItemView.prototype.attributes = function() {
      return {
        'href': "#contact/" + this.model.id
      };
    };

    ContactsListItemView.prototype.initialize = function() {
      return this.listenTo(this.model, 'change', this.render);
    };

    ContactsListItemView.prototype.getRenderData = function() {
      return this.model.attributes;
    };

    ContactsListItemView.prototype.template = require('templates/contactslist_item');

    return ContactsListItemView;

  })(BaseView);
  
});
window.require.register("views/datapoint", function(exports, require, module) {
  var BaseView, DataPointView, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseView = require('lib/base_view');

  module.exports = DataPointView = (function(_super) {
    __extends(DataPointView, _super);

    function DataPointView() {
      this.getPossibleTypes = __bind(this.getPossibleTypes, this);
      _ref = DataPointView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    DataPointView.prototype.template = require('templates/datapoint');

    DataPointView.prototype.tagName = 'li';

    DataPointView.prototype.className = 'datapoint';

    DataPointView.prototype.events = function() {
      return {
        'blur .type': 'store',
        'blur .value': 'store'
      };
    };

    DataPointView.prototype.getRenderData = function() {
      return _.extend(this.model.toJSON(), {
        placeholder: this.getPlaceHolder()
      });
    };

    DataPointView.prototype.afterRender = function() {
      this.valuefield = this.$('.value');
      this.typefield = this.$('input.type');
      return this.typefield.typeahead({
        source: this.getPossibleTypes
      });
    };

    DataPointView.prototype.getPossibleTypes = function() {
      switch (this.model.get('name')) {
        case 'about':
          return ['org', 'birthday', 'title'];
        case 'other':
          return ['skype', 'jabber', 'irc'];
        default:
          return ['main', 'home', 'work', 'assistant'];
      }
    };

    DataPointView.prototype.getPlaceHolder = function() {
      switch (this.model.get('name')) {
        case 'email':
          return 'john.smith@example.com';
        case 'adr':
          return '42 main street ...';
        case 'tel':
          return '+33 1 23 45 67 89';
        case 'url':
          return 'http://example.com/john-smith';
        case 'about':
        case 'other':
          return 'type here';
      }
    };

    DataPointView.prototype.store = function() {
      return this.model.set({
        type: this.typefield.val(),
        value: this.valuefield.val()
      });
    };

    return DataPointView;

  })(BaseView);
  
});
window.require.register("views/help", function(exports, require, module) {
  var BaseView, ContactsListItemView, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseView = require('lib/base_view');

  module.exports = ContactsListItemView = (function(_super) {
    __extends(ContactsListItemView, _super);

    function ContactsListItemView() {
      _ref = ContactsListItemView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ContactsListItemView.prototype.id = "help";

    ContactsListItemView.prototype.template = require('templates/help');

    return ContactsListItemView;

  })(BaseView);
  
});
window.require.register("views/importer", function(exports, require, module) {
  var BaseView, Contact, ImporterView, app, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  BaseView = require('lib/base_view');

  Contact = require('models/contact');

  app = require('application');

  module.exports = ImporterView = (function(_super) {
    __extends(ImporterView, _super);

    function ImporterView() {
      _ref = ImporterView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ImporterView.prototype.template = require('templates/importer');

    ImporterView.prototype.id = 'importer';

    ImporterView.prototype.tagName = 'div';

    ImporterView.prototype.className = 'modal';

    ImporterView.prototype.events = function() {
      return {
        'change #vcfupload': 'onupload',
        'click  #confirm-btn': 'addcontacts'
      };
    };

    ImporterView.prototype.afterRender = function() {
      this.$el.modal();
      this.upload = this.$('#vcfupload')[0];
      this.content = this.$('.modal-body');
      return this.confirmBtn = this.$('#confirm-btn');
    };

    ImporterView.prototype.onupload = function() {
      var file, reader, validMimeTypes, _ref1,
        _this = this;
      file = this.upload.files[0];
      validMimeTypes = ['text/vcard', 'text/x-vcard', 'text/directory', 'text/directory;profile=vcard'];
      if (_ref1 = file.type.toLowerCase(), __indexOf.call(validMimeTypes, _ref1) < 0) {
        this.$('.control-group').addClass('error');
        this.$('.help-inline').text('is not a vCard');
        return;
      }
      reader = new FileReader();
      reader.readAsText(file);
      return reader.onloadend = function() {
        var txt;
        _this.toImport = Contact.fromVCF(reader.result);
        txt = "<p>Ready to import " + _this.toImport.length + " contacts :</p><ul>";
        _this.toImport.each(function(contact) {
          return txt += "<li>" + (contact.get('fn')) + "</li>";
        });
        txt += '</ul>';
        _this.content.html(txt);
        return _this.confirmBtn.removeClass('disabled');
      };
    };

    ImporterView.prototype.addcontacts = function() {
      if (!this.toImport) {
        return true;
      }
      this.toImport.each(function(contact) {
        return contact.save(null, {
          success: function() {
            return app.contacts.add(contact);
          }
        });
      });
      return this.close();
    };

    ImporterView.prototype.close = function() {
      this.$el.modal('hide');
      return this.remove();
    };

    return ImporterView;

  })(BaseView);
  
});
