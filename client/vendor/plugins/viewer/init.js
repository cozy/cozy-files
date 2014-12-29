//jshint browser: true, strict: false, maxstatements: false
if (typeof window.plugins !== "object") {
  window.plugins = {};
}
window.plugins.viewer = {
  name: "Viewer",
  active: true,
  getFiles: function (node) {
    if (typeof node === 'undefined') {
      node = document;
    }
    return node.querySelectorAll("[data-file-url$=pdf], [data-file-url$=ods], [data-file-url$=odt]");
  },
  addGallery: function (params) {
    var files;
    files = this.getFiles();
    if (files.length > 0) {
      Array.prototype.forEach.call(files, function (elmt, idx) {
        if (elmt.dataset.hasPreview) {
          return;
        }
        elmt.dataset.hasPreview = true;
        var icon = document.createElement('a');
        icon.innerHTML = "<i class='fa fa-eye'></i>";
        icon.addEventListener('click', function () {
          var viewer;
          viewer = document.createElement('iframe');
          viewer.id = 'viewer';
          viewer.setAttribute('src', 'ViewerJS/#../' + elmt.dataset.fileUrl);
          viewer.setAttribute('height', window.innerHeight * 0.7);
          viewer.setAttribute('width', '100%');
          viewer.setAttribute('allowfullscreen', 'allowfullscreen');
          viewer.setAttribute('webkitallowfullscreen', true);
          window.plugins.helpers.modal({body: viewer.outerHTML, size: 'large'});
        });
        if (elmt.nextElementSibling) {
          elmt.parentNode.insertBefore(icon, elmt.nextElementSibling);
        } else {
          elmt.parentNode.appendChild(icon);
        }
      });
    }
  },
  onAdd: {
    condition: function (node) {
      return this.getFiles(node).length > 0;
    },
    action: function (node) {
      this.addGallery();
    }
  },
  onDelete: {
    condition: function (node) {
      return this.getFiles(node).length > 0;
    },
    action: function (node) {
      this.addGallery();
    }
  },
  onActivate: function () {
    var script = document.createElement('script');
    script.src = "http://vast-engineering.github.io/jquery-popup-overlay/jquery.popupoverlay.js";
    document.body.appendChild(script);

  },
  onDeactivate: function () {
  },
  listeners: {
    'load': function (params) {
      this.addGallery();
    }
  }
};
