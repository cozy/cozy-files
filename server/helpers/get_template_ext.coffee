fs = require 'fs'
path = require 'path'

# if the app is running from build/ it uses JS, otherwise it uses jade
module.exports = ->
    filePath = path.resolve __dirname, "../views/index.js"
    if fs.existsSync(filePath)
        ext = 'js'
    else
        ext = 'jade'

    return ext
