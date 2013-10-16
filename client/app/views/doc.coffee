BaseView = require 'lib/base_view'

module.exports = class DocView extends BaseView

    id: 'doc'
    template: require 'templates/doc'