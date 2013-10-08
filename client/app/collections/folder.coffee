Folder = require '../models/folder'

module.exports = class FolderCollection extends Backbone.Collection

    # Model that will be contained inside the collection.
    model: Folder

    # This is where ajax requests the backend.
    url: 'folders'
