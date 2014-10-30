# Make ajax request more easy to do.
# Expected callbacks: success and error
exports.request = (type, url, data, callback, json=true) ->
    if data? and json
        data = JSON.stringify data

    options =
        type: type
        url: url
        data: if data? then data else null
        contentType: if json then "application/json" else false
        dataType: if json then "json" else null
        processData: json
        success: (data) ->
            callback null, data if callback?
        error: (data) ->
            if data? and data.msg? and callback?
                callback new Error data.msg
            else if callback?
                callback new Error "Server error occured"

    $.ajax options

# Sends a get request with data as body
# Expected callbacks: success and error
exports.get = (url, callback, json) ->
    exports.request "GET", url, null, callback, json

# Sends a post request with data as body
# Expected callbacks: success and error
exports.post = (url, data, callback, json) ->
    exports.request "POST", url, data, callback, json

# Sends a put request with data as body
# Expected callbacks: success and error
exports.put = (url, data, callback, json) ->
    exports.request "PUT", url, data, callback, json

# Sends a delete request with data as body
# Expected callbacks: success and error
exports.del = (url, callback, json) ->
    exports.request "DELETE", url, null, callback, json
