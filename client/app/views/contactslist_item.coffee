BaseView = require 'lib/base_view'

module.exports = class ContactsListItemView extends BaseView

    tagName: 'a'
    className: 'contact-thumb'
    attributes: -> 'href': "#contact/#{@model.id}"

    initialize: ->
        @listenTo @model, 'change', @render

    getRenderData: -> @model.attributes

    template: require 'templates/contactslist_item'
