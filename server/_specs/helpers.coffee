TESTPORT = 8013
Contact = require '../models/contact'
Client = require('request-json').JsonClient

module.exports =


  init: (done) ->
      init = require '../../init.coffee'
      init done

  startServer: (done) ->
      @app = require '../../server.coffee'
      port = process.env.PORT or TESTPORT
      host = process.env.HOST or "127.0.0.1"
      @server = @app.listen port, host, done

  killServer: ->
      @server.close()

  clearDb: (done) ->
      Contact.requestDestroy "all", (err) ->
          done err

  createContact: (data) -> (done) ->
      baseContact = new Contact(data)
      Contact.create baseContact, (err, album) =>
          @album = album
          done err

  makeTestClient: (done) ->
      old = new Client "http://localhost:#{TESTPORT}/"

      store = this # this will be the common scope of tests

      callbackFactory = (done) -> (error, response, body) =>
          throw error if(error)
          store.response = response
          store.body = body
          done()

      clean = ->
          store.response = null
          store.body = null

      store.client =
          get: (url, done) ->
              clean()
              old.get url, callbackFactory(done)
          post: (url, data, done) ->
              clean()
              old.post url, data, callbackFactory(done)
          put: (url, data, done) ->
              clean()
              old.put url, data, callbackFactory(done)
          del: (url, done) ->
              clean()
              old.del url, callbackFactory(done)
          sendFile: (url, path, done) ->
              old.sendFile url, path, callbackFactory(done)
          saveFile: (url, path, done) ->
              old.saveFile url, path, callbackFactory(done)

      done()