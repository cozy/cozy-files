BaseView = require 'lib/base_view'

module.exports = class ContactsListItemView extends BaseView

    tagName: 'a'
    className: 'contact-thumb'
    attributes: -> 'href': "#contact/#{@model.id}"

    initialize: ->
        @listenTo @model, 'change', @render

    getRenderData: ->
        _.extend {},  @model.attributes,
          hasPicture: @model.hasPicture or false
          bestmail:   @model.getBest 'email'
          besttel:    @model.getBest 'tel'

    template: require 'templates/contactslist_item'
