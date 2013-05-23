# ContactCollection
# is a collection of Contacts (models/contact)
# define the endpoint where Backbone will fetch the list of contacts

module.exports = class ContactCollection extends Backbone.Collection

    model: require 'models/contact'
    url: 'contacts'