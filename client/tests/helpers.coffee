module.exports = (casper, utils) -> helpers =

    _test: null

    assertHasClass: (selector, className) ->
        classNames = helpers.getClassNames selector
        helpers._test.assert(
            className in classNames,
            "#{selector} has class #{className}"
        )

    assertHasntClass: (selector, className) ->
        classNames = casper.getElementAttribute selector, 'className'
        helpers._test.assert(
            className not in classNames,
            "#{selector} hasn't class #{className}"
        )

    getClassNames: (selector) ->
        classNames = casper.getElementInfo(selector).attributes.class
        return classNames.split ' '

    getElementIndexByName: (elementName) ->
        elementIndex = casper.evaluate (elementName) ->
            result = null
            selector = 'tr.folder-row'
            Array::forEach.call $(selector), (element, index) ->
                elementText = $(element).find('a.btn-link span').html()
                result = index if elementText is elementName

            return result
        , elementName

        return elementIndex

    getElementSelectorByName: (elementName) ->
        index = helpers.getElementIndexByName elementName
        selector = "tr.folder-row:nth-of-type(#{index + 1})"
        helpers._test.assertExist selector, "#{selector} should exist"
        return selector

    navigateToFolder: (folderName) ->
        casper.click "#{helpers.getElementSelectorByName folderName} a.btn-link"
        casper.waitForUrl /#folders\/[a-z0-9]+/
        casper.waitForSelector 'tr.folder-row'
        casper.wait 500

    openShareModalByName: (elementName) ->
        selector = helpers.getElementSelectorByName elementName

        casper.thenClick "#{selector} .file-share"
        casper.waitUntilVisible '#cozy-clearance-modal'

        # the modal has an animation
        casper.wait 500

    makeAccessPrivate: (elementName) ->
        helpers.openShareModalByName elementName

        # forces the access to private/limited
        casper.thenClick '#share-private'

    saveAndCloseModal: ->
        casper.thenClick '#modal-dialog-yes'
        casper.waitWhileVisible '#cozy-clearance-modal'
        # if there is a request, we wait for it to end
        casper.wait 500

    makeAccessPublic: (elementName) ->
        helpers.openShareModalByName elementName

        casper.thenClick '#share-public'
        casper.waitUntilVisible '#public-url'

        # removes all limited access
        # casper.thenClick 'li.clearance-line i.icon-remove'
