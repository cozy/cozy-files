//jshint browser: true, strict: false
//
// Allow to preview markdown files
//
if (typeof window.plugins !== "object") {
  window.plugins = {};
}
window.plugins.markdown = {
  name: "Markdown",
  active: true,
  extensions: ['md', 'markdown'],
  getFiles: function (node) {
    return window.plugins.helpers.getFiles(this.extensions, node);
  },
  addGallery: function (params) {
    var files;
    files = this.getFiles();
    if (files.length > 0) {
      Array.prototype.forEach.call(files, function (elmt, idx) {
        window.plugins.helpers.addIcon(elmt, function () {
          var xhr = new XMLHttpRequest();
          xhr.onreadystatechange = function () {
            if (xhr.readyState === 4) {
              window.plugins.helpers.modal({body: window.markdown.toHTML(xhr.responseText), size: 'large'});
            }
          };
          xhr.open('GET', elmt.dataset.fileUrl, true);
          xhr.send(null);
        });
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
  listeners: {
    'load': function (params) {
      this.addGallery();
    }
  }
};
