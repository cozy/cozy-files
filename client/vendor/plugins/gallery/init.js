//jshint browser: true, strict: false
//
// Allow to display a slideshow of every images in the folder
//
if (typeof window.plugins !== "object") {
  window.plugins = {};
}
window.plugins.gallery = {
  name: "Gallery",
  active: true,
  extensions: ['jpg', 'jpeg', 'png', 'gif'],
  getFiles: function (node) {
    return window.plugins.helpers.getFiles(this.extensions, node);
  },
  addGallery: function (params) {
    var images, gal;
    images = this.getFiles();
    if (images.length > 0) {
      gal = document.getElementById('gallery');
      if (gal === null) {
        gal = document.createElement('div');
        gal.id = "gallery";
        gal.style.display = "none";
        document.body.appendChild(gal);
      } else {
        gal.innerHTML = '';
      }
      Array.prototype.forEach.call(images, function (elmt, idx) {
        var a, img;
        a = document.createElement('a');
        a.href = elmt.dataset.fileUrl;
        img = document.createElement('img');
        a.appendChild(img);
        gal.appendChild(a);
        window.plugins.helpers.addIcon(elmt, function () {
          var event = document.createEvent("MouseEvent");
          event.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
          a.dispatchEvent(event);
        });
      });
      window.baguetteBox.run('#gallery', {
        captions: true,       // true|false - Display image captions
        buttons: 'auto',      // 'auto'|true|false - Display buttons
        async: false,         // true|false - Load files asynchronously
        preload: 2,           // [number] - How many files should be preloaded from current image
        animation: 'slideIn'  // 'slideIn'|'fadeIn'|false - Animation type
      });
    }
  },
  onAdd: {
    /**
     * Should return true if plugin applies on added subtree
     *
     * @param {DOMNode} root node of added subtree
     */
    condition: function (node) {
      return this.getFiles(node).length > 0;
    },
    /**
     * Perform action on added subtree
     *
     * @param {DOMNode} root node of added subtree
     */
    action: function (node) {
      this.addGallery();
    }
  },
  onDelete: {
    condition: function (node) {
      return this.getImages(node).length > 0;
    },
    action: function (node) {
      this.addGallery();
    }
  },
  /**
   * Called when plugin is activated
   */
  onActivate: function () {
  },
  /**
   * Called when plugin is deactivated
   */
  onDeactivate: function () {
  },
  listeners: {
    'load': function (params) {
      this.addGallery();
    }
  }
};
