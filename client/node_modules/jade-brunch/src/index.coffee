jade = require 'jade'
sysPath = require 'path'

module.exports = class JadeCompiler
  brunchPlugin: yes
  type: 'template'
  extension: 'jade'

  constructor: (@config) ->
    return

  compile: (data, path, callback) ->
    try
      content = jade.compile data,
        compileDebug: no,
        client: yes,
        filename: path,
        pretty: !!@config.plugins?.jade?.pretty
      result = "module.exports = #{content};"
    catch err
      error = err
    finally
      callback error, result

  # Add '../node_modules/jade/jade.js' to vendor files.
  include: [
    (sysPath.join __dirname, '..', 'vendor', 'runtime.js')
  ]
