cozydb = require 'cozydb'


hideEmail = (email) ->
    email.split('@')[0]
        .replace '.', ' '
        .replace '-', ' '


# Get User Information
#
# This method get current cozy user from the CozyDB API and return a filtered
# object containing the user name and email.
#
# @returns obj
#   name: string
#   email: string
#
getUserInfo = (callback) ->
    cozydb.api.getCozyUser (err, user) ->
        return callback err if err

        name = if user.public_name?.length
            user.public_name
        else
            words = hideEmail(user.email).split ' '
            words.map((word) -> word[0].toUpperCase() + word[1...]).join ' '

        callback null,
            name:  name
            email: user.email

module.exports.getUserInfo = getUserInfo


# Get Display Name
#
# This method is just a convenient wrapper around getUserInfo method that
# execute the given callback on the user.name only.
module.exports.getDisplayName = (callback) ->
    getUserInfo (err, user) ->
        return callback err if err
        callback null, user.name
