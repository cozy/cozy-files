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
    definition(module.exports, localRequire(name), module);
    var exports = cache[name] = module.exports;
    return exports;
  };

  var require = function(name, loaderPath) {
    var path = expand(name, '.');
    if (loaderPath == null) loaderPath = '/';

    if (has(cache, path)) return cache[path];
    if (has(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has(cache, dirIndex)) return cache[dirIndex];
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
module.exports = {
  initialize: function() {
    var ContactsCollection, ContactsList, Router, e, locales;

    this.locale = window.locale;
    delete window.locale;
    this.polyglot = new Polyglot();
    try {
      locales = require('locales/' + this.locale);
    } catch (_error) {
      e = _error;
      locales = require('locales/en');
    }
    this.polyglot.extend(locales);
    window.t = this.polyglot.t.bind(this.polyglot);
    ContactsCollection = require('collections/contact');
    ContactsList = require('views/contactslist');
    Router = require('router');
    this.contacts = new ContactsCollection();
    this.contactslist = new ContactsList({
      collection: this.contacts
    });
    this.contactslist.$el.appendTo($('body'));
    this.contactslist.render();
    if (window.initcontacts != null) {
      this.contacts.reset(window.initcontacts, {
        parse: true
      });
      delete window.initcontacts;
    } else {
      this.contacts.fetch();
    }
    this.router = new Router();
    return Backbone.history.start();
  }
};

});

;require.register("collections/contact", function(exports, require, module) {
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

  ContactCollection.prototype.comparator = 'fn';

  ContactCollection.prototype.initialize = function() {
    var _this = this;

    ContactCollection.__super__.initialize.apply(this, arguments);
    return this.on('change:fn', function() {
      return _this.sort();
    });
  };

  return ContactCollection;

})(Backbone.Collection);

});

;require.register("collections/datapoint", function(exports, require, module) {
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

;require.register("initialize", function(exports, require, module) {
var app;

app = require('application');

$(function() {
  jQuery.event.props.push('dataTransfer');
  return app.initialize();
});

});

;require.register("lib/base_view", function(exports, require, module) {
var BaseView, _ref,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = BaseView = (function(_super) {
  __extends(BaseView, _super);

  function BaseView() {
    this.render = __bind(this.render, this);    _ref = BaseView.__super__.constructor.apply(this, arguments);
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

;require.register("lib/call_log_reader", function(exports, require, module) {
var isAndroidCallLogExport, isIOSCallLogExport, parseDuration;

isAndroidCallLogExport = function(firstline) {
  return firstline === 'date,type,number,name,number type,duration';
};

isIOSCallLogExport = function(firstline) {
  return firstline.split("\t").length === 5;
};

parseDuration = function(duration) {
  var hours, minutes, parts, seconds, _;

  hours = minutes = seconds = 0;
  if ((parts = duration.split(':')).length === 3) {
    hours = parts[0], minutes = parts[1], seconds = parts[2];
  } else {
    switch ((parts = duration.split(' ')).length) {
      case 2:
        seconds = parts[0], _ = parts[1];
        break;
      case 4:
        minutes = parts[0], _ = parts[1], seconds = parts[2], _ = parts[3];
        break;
      case 6:
        hours = parts[0], _ = parts[1], minutes = parts[2], _ = parts[3], seconds = parts[4], _ = parts[5];
    }
  }
  return duration = hours * 3600 + minutes * 60 + seconds;
};

module.exports.parse = function(log) {
  var lines;

  lines = log.split(/\r?\n/);
  if (isAndroidCallLogExport(lines[0])) {
    lines.shift();
    lines.pop();
    return lines.map(function(line) {
      var direction, duration, number, timestamp, _, _ref;

      _ref = line.split(','), timestamp = _ref[0], direction = _ref[1], number = _ref[2], _ = _ref[3], _ = _ref[4], duration = _ref[5];
      console.log(timestamp, Date.create(timestamp));
      return {
        timestamp: Date.create(timestamp).toISOString(),
        direction: direction,
        remote: {
          tel: number
        },
        content: {
          duration: parseDuration(duration)
        }
      };
    });
  } else if (isIOSCallLogExport(lines[0])) {
    return lines.map(function(line) {
      var direction, duration, number, timestamp, _, _ref;

      _ref = line.split("\t"), direction = _ref[0], timestamp = _ref[1], duration = _ref[2], number = _ref[3], _ = _ref[4];
      return {
        timestamp: Date.create(timestamp).toISOString(),
        direction: direction,
        remote: {
          tel: number
        },
        content: {
          duration: parseDuration(duration)
        }
      };
    });
  } else {
    throw new Error("Format not parsable");
  }
};

});

;require.register("lib/phone_number", function(exports, require, module) {
var PhoneNumber, db;

module.exports = PhoneNumber = (function() {
  function PhoneNumber(value, contexte) {}

  return PhoneNumber;

})();

PhoneNumber.countryCodes = db = {};

db["0"] = "Reserved";

db["1"] = "American Samoa";

db["1"] = "Anguilla";

db["1"] = "Antigua and Barbuda";

db["1"] = "Bahamas (Commonwealth of the)";

db["1"] = "Barbados";

db["1"] = "Bermuda";

db["1"] = "British Virgin Islands";

db["1"] = "Canada";

db["1"] = "Cayman Islands";

db["1"] = "Dominica (Commonwealth of)";

db["1"] = "Dominican Republic";

db["1"] = "Grenada";

db["1"] = "Guam";

db["1"] = "Jamaica";

db["1"] = "Montserrat";

db["1"] = "Northern Mariana Islands (Commonwealth of the)";

db["1"] = "Puerto Rico";

db["1"] = "Saint Kitts and Nevis";

db["1"] = "Saint Lucia";

db["1"] = "Saint Vincent and the Grenadines";

db["1"] = "Trinidad and Tobago";

db["1"] = "Turks and Caicos Islands";

db["1"] = "United States of America";

db["1"] = "United States Virgin Islands";

db["20"] = "Egypt (Arab Republic of)";

db["210"] = "Spare code";

db["211"] = "Spare code";

db["212"] = "Morocco (Kingdom of)";

db["213"] = "Algeria (People's Democratic Republic of)";

db["214"] = "Spare code";

db["215"] = "Spare code";

db["216"] = "Tunisia";

db["217"] = "Spare code";

db["218"] = "Libya (Socialist People's Libyan Arab Jamahiriya)";

db["219"] = "Spare code";

db["220"] = "Gambia (Republic of the)";

db["221"] = "Senegal (Republic of)";

db["222"] = "Mauritania (Islamic Republic of)";

db["223"] = "Mali (Republic of)";

db["224"] = "Guinea (Republic of)";

db["225"] = "Côte d'Ivoire (Republic of)";

db["226"] = "Burkina Faso";

db["227"] = "Niger (Republic of the)";

db["228"] = "Togolese Republic";

db["229"] = "Benin (Republic of)";

db["230"] = "Mauritius (Republic of)";

db["231"] = "Liberia (Republic of)";

db["232"] = "Sierra Leone";

db["233"] = "Ghana";

db["234"] = "Nigeria (Federal Republic of)";

db["235"] = "Chad (Republic of)";

db["236"] = "Central African Republic";

db["237"] = "Cameroon (Republic of)";

db["238"] = "Cape Verde (Republic of)";

db["239"] = "Sao Tome and Principe (Democratic Republic of)";

db["240"] = "Equatorial Guinea (Republic of)";

db["241"] = "Gabonese Republic";

db["242"] = "Congo (Republic of the)";

db["243"] = "Democratic Republic of the Congo";

db["244"] = "Angola (Republic of)";

db["245"] = "Guinea-Bissau (Republic of)";

db["246"] = "Diego Garcia";

db["247"] = "Ascension";

db["248"] = "Seychelles (Republic of)";

db["249"] = "Sudan (Republic of the)";

db["250"] = "Rwanda (Republic of)";

db["251"] = "Ethiopia (Federal Democratic Republic of)";

db["252"] = "Somali Democratic Republic";

db["253"] = "Djibouti (Republic of)";

db["254"] = "Kenya (Republic of)";

db["255"] = "Tanzania (United Republic of)";

db["256"] = "Uganda (Republic of)";

db["257"] = "Burundi (Republic of)";

db["258"] = "Mozambique (Republic of)";

db["259"] = "Spare code";

db["260"] = "Zambia (Republic of)";

db["261"] = "Madagascar (Republic of)";

db["262"] = "French Departments and Territories in the Indian Ocean j";

db["263"] = "Zimbabwe (Republic of)";

db["264"] = "Namibia (Republic of)";

db["265"] = "Malawi";

db["266"] = "Lesotho (Kingdom of)";

db["267"] = "Botswana (Republic of)";

db["268"] = "Swaziland (Kingdom of)";

db["269"] = "Comoros (Union of the)";

db["269"] = "Mayotte";

db["27"] = "South Africa (Republic of)";

db["280"] = "Spare code";

db["281"] = "Spare code";

db["282"] = "Spare code";

db["283"] = "Spare code";

db["284"] = "Spare code";

db["285"] = "Spare code";

db["286"] = "Spare code";

db["287"] = "Spare code";

db["288"] = "Spare code";

db["289"] = "Spare code";

db["290"] = "Saint Helena";

db["290"] = "Tristan da Cunha";

db["291"] = "Eritrea";

db["292"] = "Spare code";

db["293"] = "Spare code";

db["294"] = "Spare code";

db["295"] = "Spare code";

db["296"] = "Spare code";

db["297"] = "Aruba";

db["298"] = "Faroe Islands";

db["299"] = "Greenland (Denmark)";

db["30"] = "Greece";

db["31"] = "Netherlands (Kingdom of the)";

db["32"] = "Belgium";

db["33"] = "France";

db["34"] = "Spain";

db["350"] = "Gibraltar";

db["351"] = "Portugal";

db["352"] = "Luxembourg";

db["353"] = "Ireland";

db["354"] = "Iceland";

db["355"] = "Albania (Republic of)";

db["356"] = "Malta";

db["357"] = "Cyprus (Republic of)";

db["358"] = "Finland";

db["359"] = "Bulgaria (Republic of)";

db["36"] = "Hungary (Republic of)";

db["370"] = "Lithuania (Republic of)";

db["371"] = "Latvia (Republic of)";

db["372"] = "Estonia (Republic of)";

db["373"] = "Moldova (Republic of)";

db["374"] = "Armenia (Republic of)";

db["375"] = "Belarus (Republic of)";

db["376"] = "Andorra (Principality of)";

db["377"] = "Monaco (Principality of)";

db["378"] = "San Marino (Republic of)";

db["379"] = "Vatican City State f";

db["380"] = "Ukraine";

db["381"] = "Serbia (Republic of)";

db["382"] = "Montenegro (Republic of)";

db["383"] = "Spare code";

db["384"] = "Spare code";

db["385"] = "Croatia (Republic of)";

db["386"] = "Slovenia (Republic of)";

db["387"] = "Bosnia and Herzegovina";

db["388"] = "Group of countries, shared code";

db["389"] = "The Former Yugoslav Republic of Macedonia";

db["39"] = "Italy";

db["39"] = "Vatican City State";

db["40"] = "Romania";

db["41"] = "Switzerland (Confederation of)";

db["420"] = "Czech Republic";

db["421"] = "Slovak Republic";

db["422"] = "Spare code";

db["423"] = "Liechtenstein (Principality of)";

db["424"] = "Spare code";

db["425"] = "Spare code";

db["426"] = "Spare code";

db["427"] = "Spare code";

db["428"] = "Spare code";

db["429"] = "Spare code";

db["43"] = "Austria";

db["44"] = "United Kingdom of Great Britain and Northern Ireland";

db["45"] = "Denmark";

db["46"] = "Sweden";

db["47"] = "Norway";

db["48"] = "Poland (Republic of)";

db["49"] = "Germany (Federal Republic of)";

db["500"] = "Falkland Islands (Malvinas)";

db["501"] = "Belize";

db["502"] = "Guatemala (Republic of)";

db["503"] = "El Salvador (Republic of)";

db["504"] = "Honduras (Republic of)";

db["505"] = "Nicaragua";

db["506"] = "Costa Rica";

db["507"] = "Panama (Republic of)";

db["508"] = "Saint Pierre and Miquelon (Collectivité territoriale de la République française)";

db["509"] = "Haiti (Republic of)";

db["51"] = "Peru";

db["52"] = "Mexico";

db["53"] = "Cuba";

db["54"] = "Argentine Republic";

db["55"] = "Brazil (Federative Republic of)";

db["56"] = "Chile";

db["57"] = "Colombia (Republic of)";

db["58"] = "Venezuela (Bolivarian Republic of)";

db["590"] = "Guadeloupe (French Department of)";

db["591"] = "Bolivia (Republic of)";

db["592"] = "Guyana";

db["593"] = "Ecuador";

db["594"] = "French Guiana (French Department of)";

db["595"] = "Paraguay (Republic of)";

db["596"] = "Martinique (French Department of)";

db["597"] = "Suriname (Republic of)";

db["598"] = "Uruguay (Eastern Republic of)";

db["599"] = "Netherlands Antilles";

db["60"] = "Malaysia";

db["61"] = "Australia i";

db["62"] = "Indonesia (Republic of)";

db["63"] = "Philippines (Republic of the)";

db["64"] = "New Zealand";

db["65"] = "Singapore (Republic of)";

db["66"] = "Thailand";

db["670"] = "Democratic Republic of Timor-Leste";

db["671"] = "Spare code";

db["672"] = "Australian External Territories g";

db["673"] = "Brunei Darussalam";

db["674"] = "Nauru (Republic of)";

db["675"] = "Papua New Guinea";

db["676"] = "Tonga (Kingdom of)";

db["677"] = "Solomon Islands";

db["678"] = "Vanuatu (Republic of)";

db["679"] = "Fiji (Republic of)";

db["680"] = "Palau (Republic of)";

db["681"] = "Wallis and Futuna (Territoire français d'outre-mer)";

db["682"] = "Cook Islands";

db["683"] = "Niue";

db["684"] = "Spare code";

db["685"] = "Samoa (Independent State of)";

db["686"] = "Kiribati (Republic of)";

db["687"] = "New Caledonia (Territoire français d'outre-mer)";

db["688"] = "Tuvalu";

db["689"] = "French Polynesia (Territoire français d'outre-mer)";

db["690"] = "Tokelau";

db["691"] = "Micronesia (Federated States of)";

db["692"] = "Marshall Islands (Republic of the)";

db["693"] = "Spare code";

db["694"] = "Spare code";

db["695"] = "Spare code";

db["696"] = "Spare code";

db["697"] = "Spare code";

db["698"] = "Spare code";

db["699"] = "Spare code";

db["7"] = "Kazakhstan (Republic of)";

db["7"] = "Russian Federation";

db["800"] = "International Freephone Service";

db["801"] = "Spare code";

db["802"] = "Spare code";

db["803"] = "Spare code";

db["804"] = "Spare code";

db["805"] = "Spare code";

db["806"] = "Spare code";

db["807"] = "Spare code";

db["808"] = "International Shared Cost Service (ISCS)";

db["809"] = "Spare code";

db["81"] = "Japan";

db["82"] = "Korea (Republic of)";

db["830"] = "Spare code";

db["831"] = "Spare code";

db["832"] = "Spare code";

db["833"] = "Spare code";

db["834"] = "Spare code";

db["835"] = "Spare code";

db["836"] = "Spare code";

db["837"] = "Spare code";

db["838"] = "Spare code";

db["839"] = "Spare code";

db["84"] = "Viet Nam (Socialist Republic of)";

db["850"] = "Democratic People's Republic of Korea";

db["851"] = "Spare code";

db["852"] = "Hong Kong, China";

db["853"] = "Macao, China";

db["854"] = "Spare code";

db["855"] = "Cambodia (Kingdom of)";

db["856"] = "Lao People's Democratic Republic";

db["857"] = "Spare code";

db["858"] = "Spare code";

db["859"] = "Spare code";

db["86"] = "China (People's Republic of)";

db["870"] = "Inmarsat SNAC";

db["871"] = "Spare code";

db["872"] = "Spare code";

db["873"] = "Spare code";

db["874"] = "Spare code";

db["875"] = "Reserved - Maritime Mobile Service Applications";

db["876"] = "Reserved - Maritime Mobile Service Applications";

db["877"] = "Reserved - Maritime Mobile Service Applications";

db["878"] = "Universal Personal Telecommunication Service (UPT) e";

db["879"] = "Reserved for national non-commercial purposes";

db["880"] = "Bangladesh (People's Republic of)";

db["881"] = "Global Mobile Satellite System (GMSS), shared code n";

db["882"] = "International Networks, shared code o";

db["883"] = "International Networks, shared code p, q";

db["884"] = "Spare code";

db["885"] = "Spare code";

db["886"] = "Taiwan, China";

db["887"] = "Spare code";

db["888"] = "Telecommunications for Disaster Relief (TDR) k";

db["889"] = "Spare code";

db["890"] = "Spare code";

db["891"] = "Spare code";

db["892"] = "Spare code";

db["893"] = "Spare code";

db["894"] = "Spare code";

db["895"] = "Spare code";

db["896"] = "Spare code";

db["897"] = "Spare code";

db["898"] = "Spare code";

db["899"] = "Spare code";

db["90"] = "Turkey";

db["91"] = "India (Republic of)";

db["92"] = "Pakistan (Islamic Republic of)";

db["93"] = "Afghanistan";

db["94"] = "Sri Lanka (Democratic Socialist Republic of)";

db["95"] = "Myanmar (Union of)";

db["960"] = "Maldives (Republic of)";

db["961"] = "Lebanon";

db["962"] = "Jordan (Hashemite Kingdom of)";

db["963"] = "Syrian Arab Republic";

db["964"] = "Iraq (Republic of)";

db["965"] = "Kuwait (State of)";

db["966"] = "Saudi Arabia (Kingdom of)";

db["967"] = "Yemen (Republic of)";

db["968"] = "Oman (Sultanate of)";

db["969"] = "Reserved - reservation currently under investigation";

db["970"] = "Reserved l";

db["971"] = "United Arab Emirates h";

db["972"] = "Israel (State of)";

db["973"] = "Bahrain (Kingdom of)";

db["974"] = "Qatar (State of)";

db["975"] = "Bhutan (Kingdom of)";

db["976"] = "Mongolia";

db["977"] = "Nepal (Federal Democratic Republic of)";

db["978"] = "Spare code";

db["979"] = "International Premium Rate Service (IPRS)";

db["98"] = "Iran (Islamic Republic of)";

db["990"] = "Spare code";

db["991"] = "Trial of a proposed new international telecommunication public";

db["992"] = "Tajikistan (Republic of)";

db["993"] = "Turkmenistan";

db["994"] = "Azerbaijani Republic";

db["995"] = "Georgia";

db["996"] = "Kyrgyz Republic";

db["997"] = "Spare code";

db["998"] = "Uzbekistan (Republic of)";

db["999"] = "Reserved for future global service";

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
    this.addItem = __bind(this.addItem, this);    _ref = ViewCollection.__super__.constructor.apply(this, arguments);
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

;require.register("locales/en", function(exports, require, module) {
module.exports = {
  "saving": "Saving ...",
  "saved": "Saved",
  "delete": "Delete",
  "delete the contact": "Delete the contact",
  "add contact": "Create a new contact",
  "go to settings": "Settings",
  "company": "Company",
  "title": "Title",
  "birthday": "Birthday",
  "phone": "Phone",
  "email": "Email",
  "postal": "Postal",
  "url": "Url",
  "other": "Other",
  "delete": "Delete",
  "add": "Add",
  "Delete the contact": "Delete the contact",
  "Name": "Name",
  "Change": "Change",
  "Take notes here": "Take notes here",
  "type here": "Type here",
  "zbout": "About",
  "phones": "Phones",
  "emails": "Emails",
  "postal": "Postal",
  "links": "Links",
  "others": "Others",
  "Saved": "Saved",
  "Save changes ?": "Save changes ?",
  "This is not an image": "This is not an image",
  "search placeholder": "Search ...",
  "New Contact": "New Contact",
  "Export vCard": "Export vCard",
  "import vcard": "Import vCard",
  "choose vcard file": "Choose a vCard file",
  "is not a vcard": "is not a vCard",
  "cancel": "Cancel",
  "import": "Import",
  "import.ready-msg": "Ready to import %{smart_count} contact |||| Ready to import %{smart_count} contacts",
  "import call log help": "If you are a FING and Orange user, do not use this",
  "import android calls": "If you use an android phone, use the following application : ",
  "import ios calls": "If you use an iOS phone, follow this tutorial : ",
  "choose log file": "Then upload your generated log file",
  "click left to display": "Click a contact in the left panel to display it",
  "carddav info": "To sync your contacts with your mobile, install the cozy-webdav application",
  "call log info": "Click here to import your mobile's call log :",
  "import call log": "Import call Log",
  "vcard import info": "Click here to import a vCard file :",
  "import vcard": "Import vCard file",
  "vcard export info": "Click here to export all your contacts as a vCard file :",
  "export all vcard": "Export vCard file"
};

});

;require.register("locales/fr", function(exports, require, module) {
module.exports = {
  "Saving ...": "Enregistrement en cours",
  "Save": "Enregistrer",
  "More": "Plus",
  "Add Company": "Ajouter Compagnie",
  "Add Title": "Ajouter poste",
  "Add Birthday": "Ajouter Anniversaire",
  "Add Phone": "Ajouter téléphone",
  "Add Email": "Ajouter Email",
  "Add Postal": "Ajouter Adresse",
  "Add Url": "Ajouter un Lien",
  "Add Other": "Ajouter autre",
  "Delete the contact": "Supprimer le contact",
  "Name": "Nom",
  "Change": "Changer",
  "Take notes here": "Ecrivez ici",
  "type here": "Ecrivez ici",
  "About": "A propos",
  "Phones": "Téléphones",
  "Emails": "Emails",
  "Postal": "Addresses",
  "Links": "Liens",
  "Others": "Autres",
  "Saved": "Enregistré",
  "Save changes ?": "Enregistrer les modifications ?",
  "This is not an image": "Ce fichier n'est pas une image",
  "Search ...": "Recherche ...",
  "New Contact": "Nouveau Contact",
  "Export vCard": "Exporter vCard",
  "Import vCard": "Importer vCard",
  "Choose a vCard file": "Choisissez un fichier vCard",
  "is not a vCard": "n'est pas un fichir vCard",
  "Cancel": "Annuler",
  "Import": "Importer",
  "import.ready-msg": "Pret à importer %{smart_count} contact |||| Pret à importer %{smart_count} contacts"
};

});

;require.register("models/contact", function(exports, require, module) {
var ANDROID_RELATION_TYPES, AndroidToDP, Contact, DataPoint, DataPointCollection,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

DataPoint = require('models/datapoint');

DataPointCollection = require('collections/datapoint');

ANDROID_RELATION_TYPES = ['custom', 'assistant', 'brother', 'child', 'domestic partner', 'father', 'friend', 'manager', 'mother', 'parent', 'partner', 'referred by', 'relative', 'sister', 'spouse'];

module.exports = Contact = (function(_super) {
  __extends(Contact, _super);

  Contact.prototype.urlRoot = 'contacts';

  function Contact() {
    this.match = __bind(this.match, this);
    this.addDP = __bind(this.addDP, this);    this.dataPoints = new DataPointCollection();
    Contact.__super__.constructor.apply(this, arguments);
  }

  Contact.prototype.defaults = function() {
    return {
      fn: '',
      note: '',
      tags: []
    };
  };

  Contact.prototype.parse = function(attrs) {
    var _ref;

    if (attrs.datapoints) {
      this.dataPoints.reset(attrs.datapoints);
      delete attrs.datapoints;
    }
    if ((_ref = attrs._attachments) != null ? _ref.picture : void 0) {
      this.hasPicture = true;
      delete attrs._attachments;
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
        _this.hasPicture = true;
        _this.trigger('change', _this, {});
        return delete _this.picture;
      };
    }
    return Contact.__super__.sync.call(this, method, model, options);
  };

  Contact.prototype.getBest = function(name) {
    var result;

    result = null;
    this.dataPoints.each(function(dp) {
      if (dp.get('name') === name) {
        if (dp.get('pref')) {
          return result = dp.get('value');
        } else {
          return result != null ? result : result = dp.get('value');
        }
      }
    });
    return result;
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

AndroidToDP = function(contact, raw) {
  var parts, type, value, _ref;

  parts = raw.split(';');
  switch (parts[0].replace('vnd.android.cursor.item/', '')) {
    case 'contact_event':
      value = parts[1];
      type = (_ref = parts[2]) === '0' || _ref === '2' ? parts[3] : parts[2] === '1' ? 'anniversary' : 'birthday';
      return contact.addDP('about', type, value);
    case 'relation':
      value = parts[1];
      type = ANDROID_RELATION_TYPES[+parts[2]];
      if (type === 'custom') {
        type = parts[3];
      }
      return contact.addDP('other', type, value);
  }
};

Contact.fromVCF = function(vcf) {
  var ContactCollection, all, current, currentdp, currentidx, currentversion, imported, itemidx, key, line, match, part, pname, properties, property, pvalue, regexps, value, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;

  regexps = {
    begin: /^BEGIN:VCARD$/i,
    end: /^END:VCARD$/i,
    simple: /^(version|fn|title|org|note)\:(.+)$/i,
    android: /^x-android-custom\:(.+)$/i,
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
          break;
        case 'bday':
          current.addDP('about', 'birthday', value);
      }
    } else if (regexps.android.test(line)) {
      _ref2 = line.match(regexps.android), all = _ref2[0], value = _ref2[1];
      AndroidToDP(current, value);
    } else if (regexps.composedkey.test(line)) {
      _ref3 = line.match(regexps.composedkey), all = _ref3[0], itemidx = _ref3[1], part = _ref3[2], value = _ref3[3];
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
        value = value.replace('_$!<', '');
        value = value.replace('>!$_', '');
        currentdp.set('type', value.toLowerCase());
      } else {
        for (_j = 0, _len1 = properties.length; _j < _len1; _j++) {
          property = properties[_j];
          _ref4 = property.match(regexps.property), all = _ref4[0], pname = _ref4[1], pvalue = _ref4[2];
          currentdp.set(pname.toLowerCase(), pvalue.toLowerCase());
        }
        if (key === 'adr') {
          value = value.join("\n").replace(/\n+/g, "\n");
        }
        if (key === 'x-abdate') {
          key = 'about';
        }
        if (key === 'x-abrelatednames') {
          key = 'other';
        }
        currentdp.set('name', key.toLowerCase());
        currentdp.set('value', value.replace("\\:", ":"));
      }
    } else if (regexps.complex.test(line)) {
      _ref5 = line.match(regexps.complex), all = _ref5[0], key = _ref5[1], properties = _ref5[2], value = _ref5[3];
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
        match = property.match(regexps.property);
        if (match) {
          all = match[0], pname = match[1], pvalue = match[2];
        } else {
          pname = 'type';
          pvalue = property;
        }
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

;require.register("models/datapoint", function(exports, require, module) {
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

;require.register("router", function(exports, require, module) {
var CallImporterView, Contact, ContactView, DocView, ImporterView, Router, app, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

app = require('application');

ContactView = require('views/contact');

DocView = require('views/doc');

ImporterView = require('views/importer');

CallImporterView = require('views/callimporter');

Contact = require('models/contact');

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    _ref = Router.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Router.prototype.routes = {
    '': 'help',
    'settings': 'help',
    'import': 'import',
    'callimport': 'callimport',
    'contact/new': 'newcontact',
    'contact/:id': 'showcontact'
  };

  Router.prototype.initialize = function() {
    var _this = this;

    return $('body').on('keyup', function(event) {
      if (event.keyCode === 27) {
        return _this.navigate("", true);
      }
    });
  };

  Router.prototype.help = function() {
    this.displayView(new DocView());
    $('#filterfied').focus();
    return app.contactslist.activate(null);
  };

  Router.prototype["import"] = function() {
    this.help();
    this.importer = new ImporterView();
    return $('body').append(this.importer.render().$el);
  };

  Router.prototype.callimport = function() {
    this.help();
    this.importer = new CallImporterView();
    return $('body').append(this.importer.render().$el);
  };

  Router.prototype.newcontact = function() {
    var contact,
      _this = this;

    contact = new Contact();
    contact.dataPoints.add({
      name: 'tel',
      type: 'main',
      value: ''
    });
    contact.dataPoints.add({
      name: 'email',
      type: 'main',
      value: ''
    });
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
      this.displayViewFor(contact);
      return app.contactslist.activate(contact);
    } else {
      alert(t("this contact doesn't exist"));
      return this.navigate('', true);
    }
  };

  Router.prototype.displayView = function(view) {
    var _ref1,
      _this = this;

    if (this.currentContact) {
      this.stopListening(this.currentContact);
    }
    if (((_ref1 = app.contactview) != null ? _ref1.needSaving : void 0) && confirm(t('Save changes ?'))) {
      app.contactview.save();
      app.contactview.model.once('sync', function() {
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
    app.contactview.$el.appendTo($('body'));
    return app.contactview.render();
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

;require.register("templates/callimporter", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="modal-header">');
var __val__ = t("import call log")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div><div id="import-file" class="modal-body"><p>');
var __val__ = t('import call log help')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</p><ul><li>');
var __val__ = t('import android calls')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('<a href="https://play.google.com/store/apps/details?id=com.dukemdev" target="_blank">Call Log Export</a></li><li>');
var __val__ = t('import ios calls')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('<a href="http://support.digidna.net/entries/22585757-Export-iPhone-Call-History-to-PC-or-Mac" target="_blank">Export iPhone Call History</a></li></ul><div class="control-group"><label for="vcfupload" class="control-label">');
var __val__ = t("choose log file")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</label><div class="controls"><input id="csvupload" type="file" accept="text/csv;text/plain"/><span class="help-inline"></span></div></div></div><div id="import-config" class="modal-body"><p>');
var __val__ = t('ready to import')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</p><table class="table stripped-table"><thead><th>');
var __val__ = t('log direction')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</th><th>');
var __val__ = t('log number')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</th><th>');
var __val__ = t('log date')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</th></thead><tbody></tbody></table></div><div class="modal-footer"><a id="cancel-btn" href="#" class="btn">');
var __val__ = t("cancel")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a><a id="confirm-btn" class="btn disabled btn-primary">');
var __val__ = t("import")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></div>');
}
return buf.join("");
};
});

;require.register("templates/contact", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<a id="close" href="#">&lt;</a><div id="picture">');
if ( hasPicture)
{
buf.push('<img');
buf.push(attrs({ 'src':("contacts/" + (id) + "/picture.png"), "class": ('picture') }, {"src":true}));
buf.push('/>');
}
else
{
buf.push('<img src="img/defaultpicture.png" class="picture"/>');
}
buf.push('<div id="uploadnotice">');
var __val__ = t("Change")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div><input id="uploader" type="file"/></div><div id="wrap-name-notes"><input');
buf.push(attrs({ 'id':('name'), 'placeholder':(t("Name")), 'value':("" + (fn) + "") }, {"placeholder":true,"value":true}));
buf.push('/><input');
buf.push(attrs({ 'id':('tags'), 'value':(tags.join(',')), "class": ('tagit') }, {"value":true}));
buf.push('/></div><span id="save-info">');
var __val__ = t('changes saved') + ' '
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('<a id="undo">');
var __val__ = t('undo')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></span><a');
buf.push(attrs({ 'id':('delete'), 'title':(t("delete the contact")) }, {"title":true}));
buf.push('>');
var __val__ = t('delete')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a><div id="zones"><div id="notes-zone" class="zone"><h2>');
var __val__ = t('notes')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</h2><textarea');
buf.push(attrs({ 'rows':("3"), 'placeholder':(t('Take notes here')), 'id':('notes') }, {"rows":true,"placeholder":true}));
buf.push('>' + escape((interp = note) == null ? '' : interp) + '</textarea></div><div id="abouts" class="zone"><h2>');
var __val__ = t("about")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</h2><ul></ul><a class="btn add addabout">');
var __val__ = t('add')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></div><div id="tels" class="zone"><h2>');
var __val__ = t("phones")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</h2><ul></ul><a class="btn add addtel">');
var __val__ = t('add')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></div><div id="emails" class="zone"><h2>');
var __val__ = t("emails")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</h2><ul></ul><a class="btn add addemail">');
var __val__ = t('add')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></div><div id="adrs" class="zone"><h2>');
var __val__ = t("postal")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</h2><ul></ul><a class="btn add addadr">');
var __val__ = t('add')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></div><div id="urls" class="zone"><h2>');
var __val__ = t("links")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</h2><ul></ul><a class="btn add addurl">');
var __val__ = t('add')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></div><div id="others" class="zone"><h2>');
var __val__ = t("others")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</h2><ul></ul><a class="btn add addother">');
var __val__ = t('add')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></div><div id="adder" class="zone"><h2>');
var __val__ = ("add")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</h2><a class="addbirthday">');
var __val__ = t("birthday") + ', '
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a><a class="addcompany">');
var __val__ = t("company") + ', '
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a><a class="addtitle">');
var __val__ = t("title") + ', '
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a><a class="addtel">');
var __val__ = t("phone") + ', '
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a><a class="addemail">');
var __val__ = t("email") + ', '
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a><a class="addadr">');
var __val__ = t("postal") + ', '
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a><a class="addurl">');
var __val__ = t("url") + ', '
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a><a class="addother">');
var __val__ = t("other")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></div></div>');
}
return buf.join("");
};
});

;require.register("templates/contactslist", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<form id="toolbar" class="form-search"><div class="input-append input-prepend"><span class="add-on"><i class="icon-search icon-white"></i></span><input');
buf.push(attrs({ 'id':('filterfield'), 'type':("text"), 'placeholder':(t("search placeholder")), "class": ('search-query') + ' ' + ('input-large') }, {"type":true,"placeholder":true}));
buf.push('/><a id="filterClean"><i class="icon-remove icon-white"></i></a></div><a');
buf.push(attrs({ 'id':('new'), 'href':("#contact/new"), 'title':(t("add contact")) }, {"href":true,"title":true}));
buf.push('><i class="icon-plus icon-white"></i></a><a');
buf.push(attrs({ 'id':('gohelp'), 'href':("#settings"), 'title':(t("go to settings")) }, {"href":true,"title":true}));
buf.push('><i class="icon-cog icon-white"></i></a></form><div id="contacts"></div>');
}
return buf.join("");
};
});

;require.register("templates/contactslist_item", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
if ( hasPicture)
{
buf.push('<img');
buf.push(attrs({ 'src':("contacts/" + (id) + "/picture.png") }, {"src":true}));
buf.push('/>');
}
else
{
buf.push('<img src="img/defaultpicture.png"/>');
}
buf.push('<h2>' + escape((interp = fn) == null ? '' : interp) + '</h2><div class="infos"><span class="email">' + escape((interp = bestmail) == null ? '' : interp) + '</span><span class="tel">  ' + escape((interp = besttel) == null ? '' : interp) + '</span></div><div class="clearfix"></div>');
}
return buf.join("");
};
});

;require.register("templates/datapoint", function(exports, require, module) {
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

;require.register("templates/doc", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<h2>');
var __val__ = t('Settings')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</h2><h3>');
var __val__ = t('Help')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</h3><p>');
var __val__ = t("click left to display")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</p><p>');
var __val__ = t("carddav info")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</p><h3>');
var __val__ = t('Import / export')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</h3><p>');
var __val__ = t("call log info") + ' '
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('<a href="#callimport">');
var __val__ = t('import call log')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></p><p>');
var __val__ = t('vcard export info') + ' '
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('<a');
buf.push(attrs({ 'href':("contacts.vcf"), 'download':("contacts.vcf"), 'title':(t("export vcard")) }, {"href":true,"download":true,"title":true}));
buf.push('>');
var __val__ = t('export all vcard')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></p><p>');
var __val__ = t("vcard import info") + ' '
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('<a href="#import">');
var __val__ = t('import vcard')
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></p>');
}
return buf.join("");
};
});

;require.register("templates/importer", function(exports, require, module) {
module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="modal-header">');
var __val__ = t("import vcard")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</div><div class="modal-body"><div class="control-group"><label for="vcfupload" class="control-label">');
var __val__ = t("choose vcard file")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</label><div class="controls"><input id="vcfupload" type="file"/><span class="help-inline"></span></div></div></div><div class="modal-footer"><a id="cancel-btn" href="#" class="btn">');
var __val__ = t("cancel")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a><a id="confirm-btn" class="btn disabled btn-primary">');
var __val__ = t("import")
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</a></div>');
}
return buf.join("");
};
});

;require.register("views/callimporter", function(exports, require, module) {
var BaseView, CallImporterView, CallLogReader, app, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('lib/base_view');

CallLogReader = require('lib/call_log_reader');

app = require('application');

module.exports = CallImporterView = (function(_super) {
  __extends(CallImporterView, _super);

  function CallImporterView() {
    _ref = CallImporterView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  CallImporterView.prototype.template = require('templates/callimporter');

  CallImporterView.prototype.id = 'callimporter';

  CallImporterView.prototype.tagName = 'div';

  CallImporterView.prototype.className = 'modal fade';

  CallImporterView.prototype.events = function() {
    return {
      'change #csvupload': 'onUpload',
      'click  #confirm-btn': 'doImport'
    };
  };

  CallImporterView.prototype.afterRender = function() {
    this.$el.modal('show');
    this.upload = this.$('#csvupload')[0];
    this.file_step = this.$('#import-file');
    this.parse_step = this.$('#import-config').hide();
    return this.confirmBtn = this.$('#confirm-btn');
  };

  CallImporterView.prototype.onUpload = function() {
    var file, reader,
      _this = this;

    file = this.upload.files[0];
    reader = new FileReader();
    reader.readAsText(file);
    reader.onloadend = function() {
      var error;

      try {
        _this.toImport = CallLogReader.parse(reader.result);
        return _this.onLogFileParsed();
      } catch (_error) {
        error = _error;
        console.log(error.stack);
        _this.$('.control-group').addClass('error');
        return _this.$('.help-inline').text(t('failed to parse'));
      }
    };
    return reader.onerror = function() {
      return console.log("ERROR READING", reader.result, reader.error);
    };
  };

  CallImporterView.prototype.onLogFileParsed = function() {
    var html, log, _i, _len, _ref1;

    this.file_step.remove();
    this.parse_step.show();
    _ref1 = this.toImport;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      log = _ref1[_i];
      html = '<tr>';
      html += "<td> " + log.direction + " </td>";
      html += "<td> " + log.remote.tel + " </td>";
      html += "<td> " + (Date.create(log.timestamp).format()) + " </td>";
      html += '</tr>';
      this.$('tbody').append($(html));
    }
    return this.confirmBtn.removeClass('disabled');
  };

  CallImporterView.prototype.doImport = function() {
    alert('@TODO');
    this.close();
    return require('application').router.navigate('');
  };

  CallImporterView.prototype.close = function() {
    this.$el.modal('hide');
    return this.remove();
  };

  return CallImporterView;

})(BaseView);

});

;require.register("views/contact", function(exports, require, module) {
var ContactView, Datapoint, TagsView, ViewCollection,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

ViewCollection = require('lib/view_collection');

TagsView = require('views/contact_tags');

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
      'click #undo': 'undo',
      'click #delete': 'delete',
      'keyup .type': 'onKeyUp',
      'keyup .value': 'onKeyUp',
      'keyup #notes': 'resizeNote',
      'change #uploader': 'photoChanged',
      'keypress .type': 'changeOccured',
      'keypress #name': 'changeOccured',
      'change #name': 'changeOccured',
      'keypress #notes': 'changeOccured',
      'change #notes': 'changeOccured'
    };
  };

  function ContactView(options) {
    this.photoChanged = __bind(this.photoChanged, this);
    this.modelChanged = __bind(this.modelChanged, this);
    this.undo = __bind(this.undo, this);
    this.save = __bind(this.save, this);
    this.changeOccured = __bind(this.changeOccured, this);    options.collection = options.model.dataPoints;
    this.saveLater = _.debounce(this.save, 1000);
    ContactView.__super__.constructor.apply(this, arguments);
  }

  ContactView.prototype.initialize = function() {
    ContactView.__super__.initialize.apply(this, arguments);
    this.listenTo(this.model, 'change', this.modelChanged);
    this.listenTo(this.model, 'request', this.onRequest);
    this.listenTo(this.model, 'error', this.onError);
    this.listenTo(this.model, 'sync', this.onSuccess);
    return this.listenTo(this.collection, 'change', this.changeOccured);
  };

  ContactView.prototype.getRenderData = function() {
    return _.extend({}, this.model.toJSON(), {
      hasPicture: this.model.hasPicture || false
    });
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
    this.savedInfo = this.$('#save-info').hide();
    this.needSaving = false;
    this.namefield = this.$('#name');
    this.notesfield = this.$('#notes');
    this.uploader = this.$('#uploader')[0];
    this.picture = this.$('#picture .picture');
    this.tags = new TagsView({
      el: this.$('#tags'),
      model: this.model,
      contactView: this
    });
    ContactView.__super__.afterRender.apply(this, arguments);
    this.$el.niceScroll();
    this.resizeNote();
    return this.currentState = this.model.toJSON();
  };

  ContactView.prototype.remove = function() {
    this.$el.getNiceScroll().remove();
    return ContactView.__super__.remove.apply(this, arguments);
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
      var point, typeField;

      event.preventDefault();
      point = new Datapoint({
        name: name
      });
      if (type != null) {
        point.set('type', type);
      }
      this.model.dataPoints.add(point);
      typeField = this.zones[name].children().last().find('.type');
      typeField.focus();
      return typeField.select();
    };
  };

  ContactView.prototype.changeOccured = function() {
    this.model.set({
      fn: this.namefield.val(),
      note: this.notesfield.val()
    });
    console.log(this.currentState, this.model.toJSON());
    if (_.isEqual(this.currentState, this.model.toJSON())) {
      return;
    }
    console.log("ACUAL CHANGE");
    this.needSaving = true;
    this.savedInfo.hide();
    return this.saveLater();
  };

  ContactView.prototype["delete"] = function() {
    if (this.model.isNew() || confirm(t('Are you sure ?'))) {
      return this.model.destroy();
    }
  };

  ContactView.prototype.save = function() {
    if (!this.needSaving) {
      return;
    }
    this.needSaving = false;
    this.savedInfo.show().text('saving changes');
    return this.model.save();
  };

  ContactView.prototype.undo = function() {
    if (!this.lastState) {
      return;
    }
    this.model.set(this.lastState, {
      parse: true
    });
    this.model.save(null, {
      undo: true
    });
    return this.resizeNote();
  };

  ContactView.prototype.onKeyUp = function(event) {
    var name, point, typeField, zone;

    if ((event.which || event.keyCode) !== 13) {
      return true;
    }
    zone = $(event.target).parents('.zone')[0].id;
    name = zone.substring(0, zone.length - 1);
    point = new Datapoint({
      name: name
    });
    this.model.dataPoints.add(point);
    typeField = this.zones[name].children().last().find('.type');
    typeField.focus();
    typeField.select();
    return false;
  };

  ContactView.prototype.resizeNote = function(event) {
    var loc, notes, rows;

    notes = this.notesfield.val();
    rows = loc = 0;
    while (loc = notes.indexOf("\n", loc) + 1) {
      rows++;
    }
    return this.notesfield.prop('rows', rows + 2);
  };

  ContactView.prototype.onRequest = function() {
    return this.spinner.show();
  };

  ContactView.prototype.onSuccess = function(model, result, options) {
    var undo,
      _this = this;

    this.spinner.hide();
    if (options.undo) {
      this.savedInfo.text(t('undone') + ' ');
      setTimeout(function() {
        return _this.savedInfo.fadeOut();
      }, 1000);
    } else {
      this.savedInfo.text(t('changes saved') + ' ');
      undo = $("<a id='undo'>" + (t('undo')) + "</a>");
      this.savedInfo.append(undo);
      this.lastState = this.currentState;
    }
    return this.currentState = this.model.toJSON();
  };

  ContactView.prototype.onError = function() {
    return this.spinner.hide();
  };

  ContactView.prototype.modelChanged = function() {
    var _ref;

    this.notesfield.val(this.model.get('note'));
    this.namefield.val(this.model.get('fn'));
    if ((_ref = this.tags) != null) {
      _ref.refresh();
    }
    return this.resizeNote();
  };

  ContactView.prototype.photoChanged = function() {
    var file, img, reader,
      _this = this;

    file = this.uploader.files[0];
    if (!file.type.match(/image\/.*/)) {
      return alert(t('This is not an image'));
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

;require.register("views/contact_tags", function(exports, require, module) {
var BaseView, TagsView, _ref,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('lib/base_view');

module.exports = TagsView = (function(_super) {
  __extends(TagsView, _super);

  function TagsView() {
    this.refresh = __bind(this.refresh, this);
    this.tagRemoved = __bind(this.tagRemoved, this);
    this.tagAdded = __bind(this.tagAdded, this);    _ref = TagsView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  TagsView.prototype.initialize = function() {
    this.$el.tagit({
      availableTags: ['test', 'toast'],
      placeholderText: t('add tags'),
      afterTagAdded: this.tagAdded,
      afterTagRemoved: this.tagRemoved
    });
    this.myOperation = false;
    return this;
  };

  TagsView.prototype.tagAdded = function(e, ui) {
    if (!(this.myOperation || ui.duringInitialization)) {
      this.model.set('tags', this.$el.tagit('assignedTags'));
      return this.options.contactView.changeOccured();
    }
  };

  TagsView.prototype.tagRemoved = function(er, ui) {
    if (!(this.myOperation || ui.duringInitialization)) {
      this.model.set('tags', this.$el.tagit('assignedTags'));
      return this.options.contactView.changeOccured();
    }
  };

  TagsView.prototype.refresh = function() {
    var tag, _i, _len, _ref1;

    this.myOperation = true;
    this.$el.tagit('removeAll');
    _ref1 = this.model.get('tags');
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      tag = _ref1[_i];
      this.$el.tagit('createTag', tag);
    }
    return this.myOperation = false;
  };

  return TagsView;

})(BaseView);

});

;require.register("views/contactslist", function(exports, require, module) {
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
    'keyup #filterfield': 'keyUpCallback',
    'click #filterClean': 'cleanFilter'
  };

  ContactsList.prototype.afterRender = function() {
    ContactsList.__super__.afterRender.apply(this, arguments);
    this.list = this.$('#contacts');
    this.filterfield = this.$('#filterfield');
    this.filterClean = this.$('#filterClean');
    this.filterClean.hide();
    this.filterfield.focus();
    return this.list.niceScroll();
  };

  ContactsList.prototype.remove = function() {
    ContactsList.__super__.remove.apply(this, arguments);
    return this.list.getNiceScroll().remove();
  };

  ContactsList.prototype.appendView = function(view) {
    return this.list.append(view.$el);
  };

  ContactsList.prototype.activate = function(model) {
    var line, outofview, position;

    this.$('.activated').removeClass('activated');
    if (!model) {
      return;
    }
    line = this.views[model.cid].$el;
    line.addClass('activated');
    position = line.position().top;
    outofview = position < 0 || position > this.list.height();
    if (outofview) {
      return this.list.scrollTop(this.list.scrollTop() + position);
    }
  };

  ContactsList.prototype.cleanFilter = function(event) {
    var id, view, _ref1, _results;

    event.preventDefault();
    this.filterfield.val('');
    this.filterClean.hide();
    _ref1 = this.views;
    _results = [];
    for (id in _ref1) {
      view = _ref1[id];
      _results.push(view.$el.show());
    }
    return _results;
  };

  ContactsList.prototype.keyUpCallback = function(event) {
    var filtertxt, firstmodel, id, match, view, _ref1;

    if (event.keyCode === 27) {
      this.filterfield.val('');
      this.filterClean.hide();
      App.router.navigate("", true);
    }
    filtertxt = this.filterfield.val();
    this.filterClean.show();
    if (!(filtertxt.length > 1 || filtertxt.length === 0)) {
      return;
    }
    this.filterClean.toggle(filtertxt.length !== 0);
    filtertxt = filtertxt.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
    this.filter = new RegExp(filtertxt, 'i');
    firstmodel = null;
    _ref1 = this.views;
    for (id in _ref1) {
      view = _ref1[id];
      match = (filtertxt === '0') || view.model.match(this.filter);
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

;require.register("views/contactslist_item", function(exports, require, module) {
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
    return _.extend({}, this.model.attributes, {
      hasPicture: this.model.hasPicture || false,
      bestmail: this.model.getBest('email'),
      besttel: this.model.getBest('tel')
    });
  };

  ContactsListItemView.prototype.template = require('templates/contactslist_item');

  return ContactsListItemView;

})(BaseView);

});

;require.register("views/datapoint", function(exports, require, module) {
var BaseView, DataPointView, _ref,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('lib/base_view');

module.exports = DataPointView = (function(_super) {
  __extends(DataPointView, _super);

  function DataPointView() {
    this.getPossibleTypes = __bind(this.getPossibleTypes, this);    _ref = DataPointView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  DataPointView.prototype.template = require('templates/datapoint');

  DataPointView.prototype.tagName = 'li';

  DataPointView.prototype.className = 'datapoint';

  DataPointView.prototype.events = function() {
    return {
      'blur .type': 'store',
      'blur .value': 'store',
      'keyup .type': 'onKeyup',
      'keyup .value': 'onKeyup'
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
        return t('type here');
    }
  };

  DataPointView.prototype.onKeyup = function(event) {
    var backspace, empty, prev;

    empty = $(event.target).val().length === 0;
    backspace = (event.which || event.keyCode) === 8;
    if (!backspace) {
      this.secondBack = false;
      return true;
    }
    if (!empty) {
      return true;
    }
    if (this.secondBack) {
      prev = this.$el.prev('li').find('.value');
      this.remove();
      if (prev) {
        return prev.focus().select();
      }
    } else {
      return this.secondBack = true;
    }
  };

  DataPointView.prototype.store = function() {
    return this.model.set({
      value: this.valuefield.val(),
      type: this.typefield.val()
    });
  };

  return DataPointView;

})(BaseView);

});

;require.register("views/doc", function(exports, require, module) {
var BaseView, DocView, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('lib/base_view');

module.exports = DocView = (function(_super) {
  __extends(DocView, _super);

  function DocView() {
    _ref = DocView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  DocView.prototype.id = 'doc';

  DocView.prototype.template = require('templates/doc');

  return DocView;

})(BaseView);

});

;require.register("views/importer", function(exports, require, module) {
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
      this.$('.help-inline').text(t('is not a vCard'));
      return;
    }
    reader = new FileReader();
    reader.readAsText(file);
    return reader.onloadend = function() {
      var txt;

      _this.toImport = Contact.fromVCF(reader.result);
      txt = t('import.ready-msg', {
        smart_count: _this.toImport
      });
      txt = "<p>" + txt + " :</p><ul>";
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

;require.register("widget", function(exports, require, module) {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

$(function() {
  var ContactsCollection, ContactsList, Router, e, homeGoTo, locales, router, _ref;

  homeGoTo = function(url) {
    var intent;

    intent = {
      action: 'goto',
      params: url
    };
    return window.parent.postMessage(intent, window.location.origin);
  };
  this.locale = window.locale;
  delete window.locale;
  this.polyglot = new Polyglot();
  try {
    locales = require('locales/' + this.locale);
  } catch (_error) {
    e = _error;
    locales = require('locales/en');
  }
  this.polyglot.extend(locales);
  window.t = this.polyglot.t.bind(this.polyglot);
  Router = (function(_super) {
    __extends(Router, _super);

    function Router() {
      _ref = Router.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Router.prototype.routes = {
      '': function() {},
      '*redirect': 'redirect'
    };

    Router.prototype.redirect = function(path) {
      this.navigate('#', {
        trigger: true
      });
      return homeGoTo('contacts/' + path);
    };

    return Router;

  })(Backbone.Router);
  ContactsCollection = require('collections/contact');
  ContactsList = require('views/contactslist');
  this.contacts = new ContactsCollection();
  this.contactslist = new ContactsList({
    collection: this.contacts
  });
  this.contactslist.$el.appendTo($('body'));
  this.contactslist.render();
  this.contacts.reset(window.initcontacts, {
    parse: true
  });
  delete window.initcontacts;
  router = new Router();
  return Backbone.history.start();
});

});

;
//@ sourceMappingURL=app.js.map