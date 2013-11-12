BaseView = require '../lib/base_view'


module.exports = class MockupView extends BaseView

    template: require './templates/mockup'
    el: "body"
