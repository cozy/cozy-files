americano = require 'americano-cozy'

Auto = (x) -> x

module.exports = Task = americano.getModel 'Task',
    done : type: Boolean, default: false
    creationDate : type: Date, default: Date.now
    completionDate : type: Date
    description : type: String
    list : type: String
    tags: Auto
