# ContactCollection
# is a collection of Contacts (models/contact)
# define the endpoint where Backbone will fetch the list of contacts

module.exports = class ContactCollection extends Backbone.Collection

    model: require 'models/contact'
    url: 'contacts'

    #sort by names
    comparator: 'fn'

    # auto resort when contact name change
    initialize: ->
        super
        @on 'change:fn', (model) =>
            @sort()
            Backbone.Mediator.publish 'contact:changed', model

    getTags: ->
        out = []
        @each (contact) -> out = out.concat contact.get 'tags'
        return _.unique out
