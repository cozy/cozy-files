require.register("cozy-clearance/contact_autocomplete", function(exports, require, module){
  module.exports = function(input, onGuestAdded, extrafilter) {
  var contactCollection;
  contactCollection = require('./contact_collection');
  if (extrafilter == null) {
    extrafilter = function() {
      return true;
    };
  }
  input.on('keyup', (function(_this) {
    return function(event) {
      if (event.which === 13 && !input.data('typeahead').shown) {
        onGuestAdded(input.val());
        input.val('');
        return event.preventDefault();
      }
    };
  })(this));
  return input.typeahead({
    source: function(query) {
      var contacts, items, regexp;
      regexp = new RegExp(query);
      contacts = contactCollection.filter(function(contact) {
        return contact.match(regexp);
      });
      items = [];
      contacts.forEach(function(contact) {
        return contact.get('emails').forEach(function(email) {
          return items.push({
            id: contact.id,
            hasPicture: contact.get('hasPicture'),
            display: "" + (contact.get('name')) + " &lt;" + email + "&gt;",
            toString: function() {
              return "" + email + ";" + contact.id;
            }
          });
        });
      });
      console.log(contacts);
      console.log(items);
      items = items.filter(extrafilter);
      return items;
    },
    matcher: function(contact) {
      var old;
      old = $.fn.typeahead.Constructor.prototype.matcher;
      return old.call(this, contact.display);
    },
    sorter: function(contacts) {
      var beginswith, caseInsensitive, caseSensitive, contact, item;
      beginswith = [];
      caseSensitive = [];
      caseInsensitive = [];
      while ((contact = contacts.shift())) {
        item = contact.display;
        if (!item.toLowerCase().indexOf(this.query.toLowerCase())) {
          beginswith.push(contact);
        } else if (~item.indexOf(this.query)) {
          caseSensitive.push(contact);
        } else {
          caseInsensitive.push(contact);
        }
      }
      return beginswith.concat(caseSensitive, caseInsensitive);
    },
    highlighter: function(contact) {
      var img, old;
      old = $.fn.typeahead.Constructor.prototype.highlighter;
      img = contact.hasPicture ? '<img width="40" src="clearance/contacts/' + contact.id + '.jpg">&nbsp;' : '<img width="40" src="images/defaultpicture.png">&nbsp;';
      return img + old.call(this, contact.display);
    },
    updater: (function(_this) {
      return function(value) {
        onGuestAdded(value);
        return "";
      };
    })(this)
  });
};

  
});

require.register("cozy-clearance/contact_collection", function(exports, require, module){
  var Contact, collection,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

collection = new Backbone.Collection();

collection.url = 'clearance/contacts';

collection.model = Contact = (function(_super) {
  __extends(Contact, _super);

  function Contact() {
    return Contact.__super__.constructor.apply(this, arguments);
  }

  Contact.prototype.match = function(filter) {
    return filter.test(this.get('name')) || this.get('emails').some(function(email) {
      return filter.test(email);
    });
  };

  return Contact;

})(Backbone.Model);

collection.fetch();

module.exports = collection;

  
});

require.register("cozy-clearance/modal", function(exports, require, module){
  var Modal,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Modal = (function(_super) {
  __extends(Modal, _super);

  function Modal() {
    this.closeOnEscape = __bind(this.closeOnEscape, this);
    return Modal.__super__.constructor.apply(this, arguments);
  }

  Modal.prototype.id = 'modal-dialog';

  Modal.prototype.className = 'modal fade';

  Modal.prototype.attributes = {
    'data-backdrop': "static",
    'data-keyboard': "false"
  };

  Modal.prototype.initialize = function(options) {
    if (this.title == null) {
      this.title = options.title;
    }
    if (this.content == null) {
      this.content = options.content;
    }
    if (this.yes == null) {
      this.yes = options.yes || 'ok';
    }
    if (this.no == null) {
      this.no = options.no || 'cancel';
    }
    if (this.cb == null) {
      this.cb = options.cb || function() {};
    }
    this.render();
    this.saving = false;
    this.$el.modal('show');
    this.$('button.close').click((function(_this) {
      return function(event) {
        event.stopPropagation();
        return _this.onNo();
      };
    })(this));
    return $(document).on('keyup', this.closeOnEscape);
  };

  Modal.prototype.events = function() {
    return {
      "click #modal-dialog-no": 'onNo',
      "click #modal-dialog-yes": 'onYes',
      'click': 'onClickAnywhere'
    };
  };

  Modal.prototype.onNo = function() {
    if (this.closing) {
      return;
    }
    this.closing = true;
    this.$el.modal('hide');
    setTimeout(((function(_this) {
      return function() {
        return _this.remove();
      };
    })(this)), 500);
    return this.cb(false);
  };

  Modal.prototype.onYes = function() {
    if (this.closing) {
      return;
    }
    this.closing = true;
    this.$el.modal('hide');
    setTimeout(((function(_this) {
      return function() {
        return _this.remove();
      };
    })(this)), 500);
    return this.cb(true);
  };

  Modal.prototype.closeOnEscape = function(e) {
    if (e.which === 27) {
      return this.onNo();
    }
  };

  Modal.prototype.remove = function() {
    $(document).off('keyup', this.closeOnEscape);
    return Modal.__super__.remove.apply(this, arguments);
  };

  Modal.prototype.render = function() {
    var body, close, container, foot, head, title, yesBtn;
    close = $('<button class="close" type="button" data-dismiss="modal" aria-hidden="true">×</button>');
    title = $('<h4 class="model-title">').text(this.title);
    head = $('<div class="modal-header">').append(close, title);
    body = $('<div class="modal-body">').append(this.renderContent());
    yesBtn = $('<button id="modal-dialog-yes" class="btn btn-cozy">').text(this.yes);
    foot = $('<div class="modal-footer">').append(yesBtn);
    if (this.no) {
      foot.prepend($('<button id="modal-dialog-no" class="btn btn-link">').text(this.no));
    }
    container = $('<div class="modal-content">').append(head, body, foot);
    container = $('<div class="modal-dialog">').append(container);
    return $("body").append(this.$el.append(container));
  };

  Modal.prototype.renderContent = function() {
    return this.content;
  };

  Modal.prototype.onClickAnywhere = function(event) {
    if (event.target.id === this.id) {
      return this.onNo();
    }
  };

  return Modal;

})(Backbone.View);

Modal.alert = function(title, content, cb) {
  return new Modal({
    title: title,
    content: content,
    yes: 'ok',
    no: null,
    cb: cb
  });
};

Modal.confirm = function(title, content, yesMsg, noMsg, cb) {
  return new Modal({
    title: title,
    content: content,
    yes: yesMsg,
    no: noMsg,
    cb: cb
  });
};

Modal.error = function(text, cb) {
  return new Modal({
    title: t('modal error'),
    content: text,
    yes: t('modal ok'),
    no: false,
    cb: cb
  });
};

module.exports = Modal;

  
});

require.register("cozy-clearance/modal_share_template", function(exports, require, module){
  function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
;var locals_for_with = (locals || {});(function (t, type, model, JSON, clearance, makeURL, undefined, Object, possible_permissions) {
buf.push("<div><div id=\"select-mode-section\"><p>" + (jade.escape(null == (jade_interp = t('modal question ' + type + ' shareable', {name: model.get('name')})) ? "" : jade_interp)) + "</p><p><button id=\"share-public\" class=\"button btn-cozy\">" + (jade.escape(null == (jade_interp = t('shared')) ? "" : jade_interp)) + "</button>&nbsp;<button id=\"share-private\" class=\"button btn-cozy\">" + (jade.escape(null == (jade_interp = t('private')) ? "" : jade_interp)) + "</button></p></div><p>&nbsp;</p></div><!-- If no clearance are set, we consider it's a private object.-->");
if ( JSON.stringify(clearance) == '[]')
{
buf.push("<p>" + (jade.escape(null == (jade_interp = t('only you can see')) ? "" : jade_interp)) + "</p>");
}
else
{
buf.push("<p>" + (jade.escape(null == (jade_interp = t('modal shared public link msg')) ? "" : jade_interp)) + "</p>");
if ( clearance == 'public')
{
buf.push("<input id=\"public-url\"" + (jade.attr("value", makeURL(), true, false)) + " class=\"form-control\"/>");
}
else
{
buf.push("<input id=\"public-url\"" + (jade.attr("value", makeURL(), true, false)) + " class=\"form-control disabled\"/>");
}
buf.push("<p>&nbsp;</p><p>" + (jade.escape(null == (jade_interp = t('modal shared with people msg')) ? "" : jade_interp)) + "</p><form role=\"form\" class=\"input-group\"><input id=\"share-input\" type=\"text\"" + (jade.attr("placeholder", t('modal shared ' + type + ' custom msg'), true, false)) + " autocomplete=\"off\" class=\"form-control\"/><a id=\"add-contact\" class=\"btn btn-cozy\">Add</a></form><ul id=\"share-list\">");
if ( clearance != 'public')
{
// iterate clearance
;(function(){
  var $$obj = clearance;
  if ('number' == typeof $$obj.length) {

    for (var i = 0, $$l = $$obj.length; i < $$l; i++) {
      var rule = $$obj[i];

if ( rule != undefined)
{
var key = rule.key
buf.push("<li class=\"clearance-line\">");
if ( rule.contact)
{
if ( rule.contact.get('hasPicture'))
{
buf.push("<img width=\"40\"" + (jade.attr("src", "clearance/contacts/" + rule.contact.id + ".jpg", true, false)) + "/>&nbsp;");
}
else
{
buf.push("<img width=\"40\" src=\"images/defaultpicture.png\"/>&nbsp;");
}
buf.push("<span class=\"clearance-name\">" + (jade.escape(null == (jade_interp = rule.contact.get('name')) ? "" : jade_interp)) + "</span>");
}
else
{
buf.push("<img width=\"40\" src=\"images/defaultpicture.png\"/><span class=\"clearance-name\">" + (jade.escape(null == (jade_interp = rule.email) ? "" : jade_interp)) + "</span>");
}
var keys = Object.keys(possible_permissions)
if ( keys.length > 1)
{
buf.push("<select" + (jade.attr("data-key", key, true, false)) + " class=\"changeperm\">");
// iterate possible_permissions
;(function(){
  var $$obj = possible_permissions;
  if ('number' == typeof $$obj.length) {

    for (var perm = 0, $$l = $$obj.length; perm < $$l; perm++) {
      var display = $$obj[perm];

buf.push("<option" + (jade.attr("value", perm, true, false)) + (jade.attr("selected", rule.perm==perm, true, false)) + ">" + (jade.escape(null == (jade_interp = ' ' + t('perm') + t(display)) ? "" : jade_interp)) + "</option>");
    }

  } else {
    var $$l = 0;
    for (var perm in $$obj) {
      $$l++;      var display = $$obj[perm];

buf.push("<option" + (jade.attr("value", perm, true, false)) + (jade.attr("selected", rule.perm==perm, true, false)) + ">" + (jade.escape(null == (jade_interp = ' ' + t('perm') + t(display)) ? "" : jade_interp)) + "</option>");
    }

  }
}).call(this);

buf.push("</select>");
}
else
{
buf.push(jade.escape(null == (jade_interp = ' ' + t('perm') + possible_permissions[keys[0]]) ? "" : jade_interp));
}
buf.push("<a" + (jade.attr("data-key", key, true, false)) + (jade.attr("title", t("revoke"), true, false)) + " class=\"clearance-btn pull-right revoke\"><i class=\"icon-remove\"></i></a><a" + (jade.attr("data-key", key, true, false)) + (jade.attr("title", t("see link"), true, false)) + (jade.attr("href", makeURL(key), true, false)) + " class=\"clearance-btn pull-right show-link\"><i class=\"glyphicon glyphicon-link\"></i></a></li>");
}
    }

  } else {
    var $$l = 0;
    for (var i in $$obj) {
      $$l++;      var rule = $$obj[i];

if ( rule != undefined)
{
var key = rule.key
buf.push("<li class=\"clearance-line\">");
if ( rule.contact)
{
if ( rule.contact.get('hasPicture'))
{
buf.push("<img width=\"40\"" + (jade.attr("src", "clearance/contacts/" + rule.contact.id + ".jpg", true, false)) + "/>&nbsp;");
}
else
{
buf.push("<img width=\"40\" src=\"images/defaultpicture.png\"/>&nbsp;");
}
buf.push("<span class=\"clearance-name\">" + (jade.escape(null == (jade_interp = rule.contact.get('name')) ? "" : jade_interp)) + "</span>");
}
else
{
buf.push("<img width=\"40\" src=\"images/defaultpicture.png\"/><span class=\"clearance-name\">" + (jade.escape(null == (jade_interp = rule.email) ? "" : jade_interp)) + "</span>");
}
var keys = Object.keys(possible_permissions)
if ( keys.length > 1)
{
buf.push("<select" + (jade.attr("data-key", key, true, false)) + " class=\"changeperm\">");
// iterate possible_permissions
;(function(){
  var $$obj = possible_permissions;
  if ('number' == typeof $$obj.length) {

    for (var perm = 0, $$l = $$obj.length; perm < $$l; perm++) {
      var display = $$obj[perm];

buf.push("<option" + (jade.attr("value", perm, true, false)) + (jade.attr("selected", rule.perm==perm, true, false)) + ">" + (jade.escape(null == (jade_interp = ' ' + t('perm') + t(display)) ? "" : jade_interp)) + "</option>");
    }

  } else {
    var $$l = 0;
    for (var perm in $$obj) {
      $$l++;      var display = $$obj[perm];

buf.push("<option" + (jade.attr("value", perm, true, false)) + (jade.attr("selected", rule.perm==perm, true, false)) + ">" + (jade.escape(null == (jade_interp = ' ' + t('perm') + t(display)) ? "" : jade_interp)) + "</option>");
    }

  }
}).call(this);

buf.push("</select>");
}
else
{
buf.push(jade.escape(null == (jade_interp = ' ' + t('perm') + possible_permissions[keys[0]]) ? "" : jade_interp));
}
buf.push("<a" + (jade.attr("data-key", key, true, false)) + (jade.attr("title", t("revoke"), true, false)) + " class=\"clearance-btn pull-right revoke\"><i class=\"icon-remove\"></i></a><a" + (jade.attr("data-key", key, true, false)) + (jade.attr("title", t("see link"), true, false)) + (jade.attr("href", makeURL(key), true, false)) + " class=\"clearance-btn pull-right show-link\"><i class=\"glyphicon glyphicon-link\"></i></a></li>");
}
    }

  }
}).call(this);

}
buf.push("</ul>");
}}("t" in locals_for_with?locals_for_with.t:typeof t!=="undefined"?t:undefined,"type" in locals_for_with?locals_for_with.type:typeof type!=="undefined"?type:undefined,"model" in locals_for_with?locals_for_with.model:typeof model!=="undefined"?model:undefined,"JSON" in locals_for_with?locals_for_with.JSON:typeof JSON!=="undefined"?JSON:undefined,"clearance" in locals_for_with?locals_for_with.clearance:typeof clearance!=="undefined"?clearance:undefined,"makeURL" in locals_for_with?locals_for_with.makeURL:typeof makeURL!=="undefined"?makeURL:undefined,"undefined" in locals_for_with?locals_for_with.undefined:typeof undefined!=="undefined"?undefined:undefined,"Object" in locals_for_with?locals_for_with.Object:typeof Object!=="undefined"?Object:undefined,"possible_permissions" in locals_for_with?locals_for_with.possible_permissions:typeof possible_permissions!=="undefined"?possible_permissions:undefined));;return buf.join("");
}
module.exports = template;
  
});

require.register("cozy-clearance/modal_share_view", function(exports, require, module){
  var CozyClearanceModal, Modal, clearanceDiff, contactCollection, contactTypeahead, randomString, request,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Modal = require("./modal");

contactTypeahead = require("./contact_autocomplete");

contactCollection = require("./contact_collection");

randomString = function(length) {
  var string;
  if (length == null) {
    length = 32;
  }
  string = "";
  while (string.length < length) {
    string += Math.random().toString(36).substr(2);
  }
  return string.substr(0, length);
};

clearanceDiff = function(now, old) {
  if (now === 'public') {
    return [];
  }
  if (old === 'public') {
    return now;
  }
  return now.filter(function(rule) {
    return !_.findWhere(old, {
      key: rule.key
    });
  });
};

request = function(method, url, data, options) {
  var params;
  params = {
    method: method,
    url: url,
    dataType: 'json',
    data: JSON.stringify(data),
    contentType: 'application/json; charset=utf-8'
  };
  return $.ajax(_.extend(params, options));
};

module.exports = CozyClearanceModal = (function(_super) {
  __extends(CozyClearanceModal, _super);

  function CozyClearanceModal() {
    this.onClose = __bind(this.onClose, this);
    this.onYes = __bind(this.onYes, this);
    this.onNo = __bind(this.onNo, this);
    this.revoke = __bind(this.revoke, this);
    this.onGuestAdded = __bind(this.onGuestAdded, this);
    this.showLink = __bind(this.showLink, this);
    this.getClearanceWithContacts = __bind(this.getClearanceWithContacts, this);
    this.existsEmail = __bind(this.existsEmail, this);
    this.typeaheadFilter = __bind(this.typeaheadFilter, this);
    this.makeURL = __bind(this.makeURL, this);
    this.getRenderData = __bind(this.getRenderData, this);
    return CozyClearanceModal.__super__.constructor.apply(this, arguments);
  }

  CozyClearanceModal.prototype.id = 'cozy-clearance-modal';

  CozyClearanceModal.prototype.template_content = require('./modal_share_template');

  CozyClearanceModal.prototype.events = function() {
    return _.extend(CozyClearanceModal.__super__.events.apply(this, arguments), {
      "click #share-public": "makePublic",
      "click #share-private": "makePrivate",
      'click #modal-dialog-share-save': 'onSave',
      'click .revoke': 'revoke',
      'click .show-link': 'showLink',
      'click #add-contact': 'onAddClicked',
      'change select.changeperm': 'changePerm'
    });
  };

  CozyClearanceModal.prototype.permissions = function() {
    return {
      'r': t('r')
    };
  };

  CozyClearanceModal.prototype.initialize = function(options) {
    this.cb = this.onClose;
    this.model = options.model;
    this.model.set('clearance', this.model.get('clearance') || []);
    this.initState = JSON.parse(JSON.stringify(this.model.get('clearance')));
    this.title = t('sharing');
    this.yes = t('save');
    this.no = t('cancel');
    return CozyClearanceModal.__super__.initialize.apply(this, arguments);
  };

  CozyClearanceModal.prototype.getRenderData = function() {
    return {
      type: this.model.get('type'),
      model: this.model,
      clearance: this.getClearanceWithContacts(),
      makeURL: this.makeURL,
      possible_permissions: this.permissions(),
      t: t
    };
  };

  CozyClearanceModal.prototype.render = function() {
    var body;
    CozyClearanceModal.__super__.render.call(this);
    body = $('.modal-body');
    return body.append($("<span class='pull-left'>" + (t('send email hint')) + "</span>"));
  };

  CozyClearanceModal.prototype.renderContent = function() {
    return $('<p>Please wait</p>');
  };

  CozyClearanceModal.prototype.afterRender = function() {
    var clearance;
    clearance = this.model.get('clearance') || [];
    this._checkToggleButtonState(clearance);
    this._configureTypeAhead(clearance);
    this._firstFocus(clearance);
    if (this.isPublicClearance()) {
      return this.$('#public-url').removeClass('disabled');
    } else {
      return this.$('#public-url').addClass('disabled');
    }
  };

  CozyClearanceModal.prototype._checkToggleButtonState = function(clearance) {
    if (typeof clearance === "object" && clearance.length === 0) {
      return this.$('#share-private').addClass('toggled');
    } else {
      return this.$('#share-public').addClass('toggled');
    }
  };

  CozyClearanceModal.prototype._configureTypeAhead = function(clearance) {
    var input;
    if (typeof clearance !== "object" || clearance.length > 0) {
      input = this.$('#share-input');
      return contactTypeahead(input, this.onGuestAdded, this.typeaheadFilter);
    }
  };

  CozyClearanceModal.prototype._firstFocus = function(clearance) {
    return setTimeout((function(_this) {
      return function() {
        if (_this.isPublicClearance()) {
          return _this.$('#public-url').focus().select();
        } else if (clearance.length > 0) {
          return _this.$('input#share-input').select();
        }
      };
    })(this), 200);
  };

  CozyClearanceModal.prototype.refresh = function() {
    this.$('.modal-body').html(this.template_content(this.getRenderData()));
    return this.afterRender();
  };

  CozyClearanceModal.prototype.makePublic = function() {
    if (this.lastClearance != null) {
      this.model.set({
        clearance: this.lastClearance
      });
    } else {
      this.model.set({
        clearance: 'public'
      });
    }
    return this.refresh();
  };

  CozyClearanceModal.prototype.makePrivate = function() {
    this.lastClearance = this.model.get('clearance');
    this.model.set({
      clearance: []
    });
    return this.refresh();
  };

  CozyClearanceModal.prototype.makeURL = function(key) {
    var url;
    url = this.model.getPublicURL();
    if (key) {
      url += '?key=' + key;
    }
    return url;
  };

  CozyClearanceModal.prototype.typeaheadFilter = function(item) {
    return !this.existsEmail(item.toString().split(';')[0]);
  };

  CozyClearanceModal.prototype.existsEmail = function(email) {
    return _.some(this.model.get('clearance'), function(rule) {
      return rule.email === email;
    });
  };

  CozyClearanceModal.prototype.getClearanceWithContacts = function(clearance) {
    if (clearance == null) {
      clearance = this.model.get('clearance') || [];
    }
    if (typeof clearance === "object") {
      clearance = clearance.map(function(rule) {
        var out;
        out = _.clone(rule);
        if (out.contactid) {
          out.contact = contactCollection.get(rule.contactid);
        }
        return out;
      });
    }
    return clearance;
  };

  CozyClearanceModal.prototype.doSave = function(sendmail, clearances) {
    return request('PUT', "clearance/" + this.model.id, this.saveData(), {
      error: function() {
        return Modal.error('server error occured');
      },
      success: (function(_this) {
        return function(data) {
          _this.model.trigger('change', _this.model);
          if (!sendmail) {
            return _this.$el.modal('hide');
          } else {
            return request('POST', "clearance/" + _this.model.id + "/send", clearances, {
              error: function() {
                return Modal.error('mail not send');
              },
              success: function(data) {
                return _this.$el.modal('hide');
              }
            });
          }
        };
      })(this)
    });
  };

  CozyClearanceModal.prototype.saveData = function() {
    return {
      clearance: this.model.get('clearance')
    };
  };

  CozyClearanceModal.prototype.showLink = function(event) {
    var label, line, link, url, urlField;
    line = $(event.target).parents('li');
    if (line.find('.linkshow').length === 0) {
      link = $(event.currentTarget);
      url = link.prop('href');
      line = $('<div class="linkshow">');
      label = $('<label>').text(t('copy paste link'));
      urlField = $('<input type="text">').val(url);
      link.parents('li').append(line.append(label, urlField));
      urlField.focus().select();
      event.preventDefault();
    } else {
      line.find('.linkshow').remove();
    }
    return false;
  };

  CozyClearanceModal.prototype.isPublicClearance = function() {
    return this.model.get('clearance') === 'public';
  };

  CozyClearanceModal.prototype.onAddClicked = function() {
    return this.onGuestAdded(this.$('#share-input').val());
  };

  CozyClearanceModal.prototype.onGuestAdded = function(result) {
    var contactid, email, isEmailEmpty, key, perm, _ref;
    _ref = result.split(';'), email = _ref[0], contactid = _ref[1];
    isEmailEmpty = email === '' || email.indexOf('@') < 1;
    if (!(this.existsEmail(email) || isEmailEmpty)) {
      key = randomString();
      perm = 'r';
      if (this.isPublicClearance()) {
        this.model.set('clearance', []);
      }
      this.model.get('clearance').push({
        contactid: contactid,
        email: email,
        key: key,
        perm: perm
      });
      return this.refresh();
    } else {
      return null;
    }
  };

  CozyClearanceModal.prototype.revoke = function(event) {
    var clearance;
    clearance = this.model.get('clearance').filter(function(rule) {
      return rule.key !== event.currentTarget.dataset.key;
    });
    if (clearance.length === 0) {
      this.model.set({
        clearance: 'public'
      });
    } else {
      this.model.set({
        clearance: clearance
      });
    }
    return this.refresh();
  };

  CozyClearanceModal.prototype.changePerm = function(event) {
    var select;
    select = event.currentTarget;
    this.model.get('clearance').filter(function(rule) {
      return rule.key === select.dataset.key;
    })[0].perm = select.options[select.selectedIndex].value;
    return this.refresh();
  };

  CozyClearanceModal.prototype.onNo = function() {
    var clearance, diffLength, diffNews, hasChanged;
    clearance = this.model.get('clearance');
    diffNews = clearanceDiff(clearance, this.initState).length !== 0;
    diffLength = clearance.length !== this.initState.length;
    hasChanged = diffNews || diffLength;
    if (hasChanged) {
      return Modal.confirm(t("confirm"), t('share confirm save'), t("yes"), t("no"), (function(_this) {
        return function(confirmed) {
          if (confirmed) {
            return CozyClearanceModal.__super__.onNo.apply(_this, arguments);
          }
        };
      })(this));
    } else {
      return CozyClearanceModal.__super__.onNo.apply(this, arguments);
    }
  };

  CozyClearanceModal.prototype.onYes = function() {
    var clearance, diffNews;
    clearance = this.model.get('clearance');
    diffNews = clearanceDiff(clearance, this.initState).length !== 0;
    if (this.$('#share-input').val() && !diffNews) {
      return Modal.confirm(t("confirm"), t('share forgot add'), t("no forgot"), t("yes forgot"), (function(_this) {
        return function(confirmed) {
          if (confirmed) {
            return CozyClearanceModal.__super__.onYes.apply(_this, arguments);
          }
        };
      })(this));
    } else {
      return CozyClearanceModal.__super__.onYes.apply(this, arguments);
    }
  };

  CozyClearanceModal.prototype.onClose = function(saving) {
    var newClearances, text;
    if (!saving) {
      return this.model.set({
        clearance: this.initState
      });
    } else {
      newClearances = clearanceDiff(this.model.get('clearance'), this.initState);
      if (newClearances.length) {
        text = t("send mails question") + newClearances.map(function(rule) {
          return rule.email;
        }).join(', ');
        return Modal.confirm(t("modal send mails"), text, t("yes"), t("no"), (function(_this) {
          return function(sendmail) {
            return _this.doSave(sendmail, newClearances);
          };
        })(this));
      } else {
        return this.doSave(false);
      }
    }
  };

  return CozyClearanceModal;

})(Modal);

  
});
