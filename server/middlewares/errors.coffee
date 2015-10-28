util = require 'util'
logger = require('printit')
    date: true

module.exports = (err, req, res, next) ->

    statusCode = err.status or 500
    message = if err instanceof Error then err.message else err.error
    message = message or 'Server error occurred' # default message

    if err.headers? and Object.keys(err.headers).length > 0
        res.set header, value for header, value of err.headers

    if err.template? and req?.accepts('html') is 'html'
        templateName = "#{err.template.name}"
        res.render templateName, err.template.params, (err, html) ->
            res.status(statusCode).send html
    else
        res.status(statusCode).send error: message

    if err instanceof Error
        logger.error err.message
        logger.error err.stack
