//jshint browser: true, strict: false
if (typeof window.plugins !== "object") {
  window.plugins = {};
}
window.plugins.markdown = {
  name: "Markdown",
  active: true,
  getFiles: function (node) {
    if (typeof node === 'undefined') {
      node = document;
    }
    return node.querySelectorAll("[data-file-url$=md], [data-file-url$=markdown]");
  },
  addGallery: function (params) {
    var files;
    files = this.getFiles();
    if (files.length > 0) {
      Array.prototype.forEach.call(files, function (elmt, idx) {
        if (elmt.parentNode.querySelectorAll("[data-markdown]").length === 0) {
          var icon = document.createElement('a');
          icon.innerHTML = "<i class='fa fa-eye' data-markdown></i>";
          icon.addEventListener('click', function () {
            var xhr = new XMLHttpRequest(), popup, config, close;
            xhr.onreadystatechange = function () {
              if (xhr.readyState === 4) {
                popup = document.createElement('div');
                popup.innerHTML = window.markdown.toHTML(xhr.responseText);
                popup.style.width  = "66%";
                popup.style.padding = "5em";
                popup.style.backgroundColor = '#EEE';
                close = document.createElement('a');
                close.innerHTML = "<i class='fa fa-times'></i>";
                close.id = "popupClose";
                close.style.fontSize = "2em";
                close.style.position = "absolute";
                close.style.top = "1em";
                close.style.right = "1em";
                popup.appendChild(close);
                document.body.appendChild(popup);
                config = {
                  autoopen: true,
                  color: '#FFF',
                  opacity: 0.5,
                  detach: true,
                  closeelement: '#popupClose'
                };
                window.jQuery(popup).popup(config);
              }
            };
            xhr.open('GET', elmt.dataset.fileUrl, true);
            xhr.send(null);

          });
          if (elmt.nextElementSibling) {
            elmt.parentNode.insertBefore(icon, elmt.nextElementSibling);
          } else {
            elmt.parentNode.appendChild(icon);
          }
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
