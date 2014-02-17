util = require 'util'
logger = require('printit')
    date: true

module.exports = (err, req, res, next) ->
    statusCode = err.status or 500
    message = if err instanceof Error then err.message else err.error

    logger.error "An error occured: #{message}"
    console.log err.stack

    res.send statusCode, error: message
