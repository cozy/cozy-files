americano = require 'americano-cozy'

module.exports = Contact = americano.getModel 'Contact',
    fn            : String
    n             : String
    datapoints    : (x) -> x