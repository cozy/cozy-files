americano = require 'americano-cozy'

module.exports = User = americano.getModel 'User',
    email: String
    password: String
    salt: String
    public_name: String
    timezone: String
    owner: Boolean
    activated: Boolean

User.first = (callback) ->
    User.request 'all', (err, users) ->
        if err? then callback new Error err
        else if not users or users.length is 0 then callback null, null
        else  callback null, users[0]

User.getDisplayName = (callback) ->
    User.first (err, user) ->
        if user?
            # display name management
            if user.public_name?.length > 0 then name = user.public_name
            else
                name = helpers.hideEmail user.email
                words = name.split ' '
                name = words.map((word) ->
                    return word.charAt(0).toUpperCase() + word.slice 1
                ).join ' '
            callback null, name
        else
            callback null, null