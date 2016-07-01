//jshint browser: true, strict: false
//
// Allow to preview medias files
//
if (typeof window.plugins !== "object") {
  window.plugins = {};
}
window.plugins.medias = {
  name: "Medias",
  active: true,
  getFiles: function (node) {
    return document.querySelectorAll('[data-file-type="music"], [data-file-type="video"]')
  },
  addGallery: function (params) {
    var files;
    files = this.getFiles();
    if (files.length > 0) {
      Array.prototype.forEach.call(files, function (elmt, idx) {
        window.plugins.helpers.addIcon(elmt, function () {
          switch (elmt.dataset.fileType) {
            case 'music':
              window.plugins.helpers.modal({body: '<div style="text-align: center"><audio src="' + elmt.dataset.fileUrl + '" autoplay="true" controls="true" ></audio></div>', size: 'large'});
              break;
            case 'video':
              window.plugins.helpers.modal({body: '<div style="text-align: center"><video src="' + elmt.dataset.fileUrl + '" autoplay="true" controls="true"></video></div>', size: 'large'});
              break;
          }
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
