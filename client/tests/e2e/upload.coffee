__utils__ = require('clientutils').create()

helpers = require('../helpers')(casper, __utils__)

casper.options.viewportSize = width: 1280, height: 800

uploadButton = '#button-upload-new-file'

casper.test.begin 'Upload - upload one file', (test) ->

    casper.start 'http://localhost:9121', ->

        test.assertTitle 'Cozy - Files', 'Checks that application is properly started'
        test.assertVisible uploadButton, 'Upload button should be visible'

    casper.run -> test.done()

# To be implemented
casper.test.begin 'Upload - upload multiple files', (test) ->
    test.done()
casper.test.begin 'Upload - upload one folder', (test) ->
    test.done()
casper.test.begin 'Upload - upload files through drag an drop', (test) ->
    test.done()
