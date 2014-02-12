module.exports = (err, req, res, next) ->

    statusCode = err.status or 500
    message = if err instanceof Error then err.message else err.error

    res.send statusCode, error: message
