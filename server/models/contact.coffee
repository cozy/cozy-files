db = require '../db/cozy-adapter'

module.exports = db.define 'Contact',
    id            : String
    name          : String
    datapoints    : [Object]
    notes         : String