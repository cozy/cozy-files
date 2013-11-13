module.exports = class Config extends Backbone.Model

    url: 'config'
    isNew: -> true
    defaults: 'nameOrder':'given-familly'

