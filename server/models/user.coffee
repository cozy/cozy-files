cozydb = require 'cozydb'


hideEmail = (email) ->
    email.split('@')[0]
        .replace '.', ' '
        .replace '-', ' '

module.exports.getDisplayName = (callback) ->
    cozydb.api.getCozyUser (err, user) ->
        if user?
            # display name management
            if user.public_name?.length > 0 then name = user.public_name
            else
                name = hideEmail user.email
                words = name.split ' '
                name = words.map((word) ->
                    return word.charAt(0).toUpperCase() + word.slice 1
                ).join ' '
            callback null, name
        else
            callback null, null


module.exports.getEmail = (callback) ->
    cozydb.api.getCozyUser (err, user) ->
        if user?
            callback null, user.email
        else
            # FIXME: Why the hell do we returns err == null if we cannot get a
            # valid user? (copied from L22)
            # In the meantime, I suggest we, at least, returns {user: undefined}
            callback {user: undefined}
