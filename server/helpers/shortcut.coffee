module.exports = (req, res, next) ->

    res.error = (code, msg, err) ->
        console.log msg
        if err
            console.log err
            console.log err.stack
        res.send error:msg, code
        return msg

    res.success = (msg, code) ->
        res.send success:msg

    next()