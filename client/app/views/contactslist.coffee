ViewCollection = require 'lib/view_collection'

# "Home" view : the list of contacts
# simple ViewCollection

module.exports = class ContactsList extends ViewCollection

    id: 'contacts-list'
    itemView: require 'views/contactslist_item'

    afterRender: ->
        super
        @collection.fetch()
