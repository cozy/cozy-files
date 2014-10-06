__utils__ = require('clientutils').create()

helpers = require('../helpers')(casper, __utils__)

scIndex = 1
sc = (fileName) ->
    casper.capture "#{fileName}-#{scIndex}.png"
    scIndex++

casper.options.viewportSize = width: 1280, height: 800
casper.test.begin 'Share - share an element in public', (test) ->
    link = null
    casper.start 'http://localhost:9121', ->
        test.assertTitle 'Cozy - Files', 'Checks that application is properly started'

        test.assertExist '.file-share:first-of-type'
        elem = @evaluate ->
            return __utils__.findOne '.file-share:first-of-type span'

        test.assert elem.className.indexOf('fa-lock') isnt -1

    casper.thenClick '.file-share:first-of-type'

    casper.waitUntilVisible '#cozy-clearance-modal'
    # the modal has an animation
    casper.wait 500

    casper.thenClick '#share-public'
    casper.waitUntilVisible '#public-url'
    casper.then ->
        link = @evaluate ->
            return __utils__.findOne('#public-url').value
        link = link.replace 'public/files/', 'public/'
        casper.open(link).then (response) ->
            test.assertEqual response.status, 404, "The element shouldn't be publicly accessible"

    casper.then -> @back()

    casper.thenClick '.file-share:first-of-type'
    casper.waitUntilVisible '#cozy-clearance-modal'
    # the modal has an animation
    casper.wait 500

    casper.thenClick '#share-public'
    casper.waitUntilVisible '#public-url'

    casper.thenClick '#modal-dialog-yes'
    casper.waitWhileVisible '#cozy-clearance-modal'
    casper.wait 500, ->
        elem = @evaluate ->
            return __utils__.findOne '.file-share:first-of-type span'
        test.assert elem.className.indexOf('fa-lock') is -1
        test.assert elem.className.indexOf('fa-globe') isnt -1

        casper.open(link).then (response) ->
            test.assertEqual response.status, 200, "The element should be publicly accessible"

    # restores initial state
    casper.then -> @back()
    casper.thenClick '.file-share:first-of-type'

    casper.waitUntilVisible '#cozy-clearance-modal'
    # the modal has an animation
    casper.wait 500

    casper.thenClick '#share-private'
    casper.thenClick '#modal-dialog-yes'
    casper.wait 500

    casper.run -> test.done()

casper.test.begin 'Share - share an element in private', (test) ->
    publicLink = null
    limitedLink = null
    casper.start 'http://localhost:9121', ->

        test.assertExist '.file-share:first-of-type'
        elem = @evaluate ->
            return __utils__.findOne '.file-share:first-of-type span'

        test.assert elem.className.indexOf('fa-lock') isnt -1

    casper.thenClick '.file-share:first-of-type'

    casper.waitUntilVisible '#cozy-clearance-modal'
    # the modal has an animation
    casper.wait 500
    casper.then ->
        test.assertVisible '#share-input'
        elementsNum = @evaluate -> return __utils__.findAll("#share-list li.clearance-line").length
        test.assertEqual elementsNum, 0

    casper.then ->
        casper.sendKeys '#share-input', 'test@test.com'
    casper.thenClick '#add-contact'
    casper.then ->
        elementsNum = @evaluate -> return __utils__.findAll("#share-list li.clearance-line").length
        test.assertEqual elementsNum, 1

    casper.thenClick 'li.clearance-line i.glyphicon-link'
    casper.then ->
        test.assertVisible 'li.clearance-line .linkshow'

    casper.then ->
        limitedLink = @evaluate ->
            return __utils__.findOne('li.clearance-line .linkshow input').value
        limitedLink = limitedLink.replace 'public/files/', 'public/'
        casper.open(limitedLink).then (response) ->
            test.assertEqual response.status, 404, "The element shouldn't be publicly accessible"

    casper.then -> @back()

    casper.thenClick '.file-share:first-of-type'

    casper.waitUntilVisible '#cozy-clearance-modal'
    # the modal has an animation
    casper.wait 500
    casper.then ->
        test.assertVisible '#share-input'
        elementsNum = @evaluate -> return __utils__.findAll("#share-list li.clearance-line").length
        test.assertEqual elementsNum, 0

    casper.then ->
        casper.sendKeys '#share-input', 'test@test.com'
    casper.thenClick '#add-contact'
    casper.then ->
        elementsNum = @evaluate -> return __utils__.findAll("#share-list li.clearance-line").length
        test.assertEqual elementsNum, 1

    casper.thenClick 'li.clearance-line i.glyphicon-link'
    casper.then ->
        test.assertVisible 'li.clearance-line .linkshow'

        limitedLink = @evaluate ->
            return __utils__.findOne('li.clearance-line .linkshow input').value
        limitedLink = limitedLink.replace 'public/files/', 'public/'
    casper.thenClick '#modal-dialog-yes'
    # clearance modal hides
    casper.waitWhileVisible '#cozy-clearance-modal'
    casper.wait 500
    # asks to send an email modal shows
    casper.then ->
        test.assertVisible '#modal-dialog-yes'
        test.assertVisible '#modal-dialog-no'
    casper.thenClick '#modal-dialog-no'
    # asks to send an email modal hides
    casper.waitWhileVisible '#cozy-clearance-modal'
    casper.wait 500, ->
        elem = @evaluate ->
            return __utils__.findOne '.file-share:first-of-type span'
        test.assert elem.className.indexOf('fa-lock') is -1
        test.assert elem.className.indexOf('fa-users') isnt -1


        casper.open(limitedLink).then (response) ->
            test.assertEqual response.status, 200, "The element should be limitedly accessible"

    # restores initial state
    casper.then -> @back()
    casper.thenClick '.file-share:first-of-type'

    casper.waitUntilVisible '#cozy-clearance-modal'
    # the modal has an animation
    casper.wait 500
    casper.then ->
        test.assertVisible '#share-input'
        elementsNum = @evaluate -> return __utils__.findAll("#share-list li.clearance-line").length
        test.assertEqual elementsNum, 1

    casper.thenClick 'li.clearance-line i.icon-remove'
    casper.then ->
        test.assertVisible '#share-input'
        elementsNum = @evaluate -> return __utils__.findAll("#share-list li.clearance-line").length
        test.assertEqual elementsNum, 0

    casper.thenClick '#modal-dialog-yes'
    # clearance modal hides
    casper.waitWhileVisible '#cozy-clearance-modal'
    casper.wait 500
    casper.then ->
        elem = @evaluate ->
            return __utils__.findOne '.file-share:first-of-type span'
        test.assert elem.className.indexOf('fa-lock') isnt -1

        casper.open(limitedLink).then (response) ->
            test.assertEqual response.status, 404, "The element shouldn't be accessible anymore"

    casper.run -> test.done()
