__utils__ = require('clientutils').create()

helpers = require('../helpers')(casper, __utils__)

casper.options.viewportSize = width: 1280, height: 800

firstElement = "tr.folder-row:first-of-type"
elementIcon = "#{firstElement} .fa.fa-folder"
elementCheckbox = "#{firstElement} .selector-wrapper button"
allCheckedInList = "tr.folder-row .selector-wrapper button .fa-check-square-o"

casper.test.begin 'Bulk actions - select all', (test) ->

    helpers._test = test

    casper.start 'http://localhost:9121', ->

        test.assertTitle 'Cozy - Files', 'Checks that application is properly started'
        test.assertNotVisible '#button-bulk-move', "'Move all' button shouldn't be visible"
        test.assertNotVisible '#button-bulk-remove', "'Remove all' button shouldn't be visible"

        test.assertVisible 'button#select-all', 'The select all button should be visible'

    casper.thenClick 'button#select-all'

    casper.waitUntilVisible '#button-bulk-move, #button-bulk-remove', ->

        test.assertVisible 'button#select-all i.fa-check-square-o', "Checked icon should be visible"
        test.assertVisible '#button-bulk-move', "'Move all' button should be visible"
        test.assertVisible '#button-bulk-remove', "'Remove all' button should be visible"

    casper.thenClick 'button#select-all'

    casper.waitWhileVisible '#button-bulk-move, #button-bulk-remove', ->
        test.assertVisible 'button#select-all i.fa-square-o', "Checked icon should be visible"
        test.assertNotVisible '#button-bulk-move', "'Move all' button shouldn't be visible"
        test.assertNotVisible '#button-bulk-remove', "'Remove all' button shouldn't be visible"

    casper.run -> test.done()

casper.test.begin 'Bulk actions - select one item', (test) ->

    casper.start 'http://localhost:9121', ->
        test.assertExist 'tr.folder-row', 'There should be elements in the list'
        test.assertNotVisible '#button-bulk-move', "'Move all' button shouldn't be visible"
        test.assertNotVisible '#button-bulk-remove', "'Remove all' button shouldn't be visible"
        test.assertElementCount allCheckedInList, 0, "No checkbox should be checked"

    casper.thenClick elementCheckbox

    casper.waitUntilVisible '#button-bulk-move, #button-bulk-remove', ->
        test.assertVisible '#button-bulk-move', "'Move all' button should be visible"
        test.assertVisible '#button-bulk-remove', "'Remove all' button should be visible"
        test.assertVisible 'button#select-all i.fa-minus-square-o', "Crossed icon should be visible"

    casper.run  -> test.done()


casper.test.begin 'Bulk actions - selecting 3 items doesnt check the "select-all" checkbox', (test) ->

    casper.start 'http://localhost:9121', ->
        test.assertExist 'tr.folder-row', 'There should be elements in the list'
        test.assertExist 'button#select-all', 'The select all button should be visible'
        test.assertElementCount allCheckedInList, 0, "No checkbox should be checked"

    casper.then ->
        for i in [1..2] by 1
            @click ".folder-row:nth-of-type(#{i}) .selector-wrapper button"

    casper.then -> test.assertVisible 'button#select-all i.fa-minus-square-o', "'Select all' checkbox shouldn't be checked"

    casper.thenClick ".folder-row:nth-of-type(3) .selector-wrapper button"

    casper.then -> test.assertVisible 'button#select-all i.fa-minus-square-o', "'Select all' checkbox shouldn't be checked"

    casper.run -> test.done()


casper.test.begin 'Bulk actions - selecting all items when there are least than 3 items, should check the "select all" checkbox (non regression)', (test) ->

    casper.start 'http://localhost:9121', ->

        imageFolderSelector = helpers.getElementSelectorByName 'Mes images'
        test.assertExist imageFolderSelector
        test.assertVisible imageFolderSelector

        helpers.navigateToFolder 'Mes images'

    casper.then ->

        test.assertExist 'button#select-all', 'The select all button should be visible'
        test.assertElementCount allCheckedInList, 0, "No checkbox should be checked"

        itemsNum = @evaluate ->
            return __utils__.findAll("tr.folder-row").length
        test.assert (0 < itemsNum < 3), "There should be strictly between 1 and 3 items"

    casper.thenClick "button#select-all"

    casper.then ->
        test.assertVisible 'button#select-all i.fa-check-square-o', 'The select-all checkbox should be checked'

    casper.run -> test.done()

casper.test.begin 'Bulk actions - move all files to a folder', (test) ->

    movedElementsNum = null

    casper.start 'http://localhost:9121', ->
        imageFolderSelector = helpers.getElementSelectorByName 'Mes images'
        test.assertEval ->
            return __utils__.findAll("tr.folder-row .fa-folder").length > 0
        , "There should must be at least one folder"

        test.assertExist imageFolderSelector
        test.assertVisible imageFolderSelector

        helpers.navigateToFolder 'Mes images'

    casper.then ->
        movedElementsNum = @evaluate ->
            return __utils__.findAll("tr.folder-row").length
        test.assert(
            movedElementsNum > 0,
            "There should must be at least one item")

        @click "button#select-all"

    casper.thenClick '#button-bulk-move'

    casper.waitUntilVisible '.modal-dialog'

    # the modal has an animation
    casper.wait 500, ->
        availableOptions = @evaluate ->
            options = __utils__.findAll '.move-select option'
            return Array::map.call options, (option) ->
                return option.textContent

        photoIndex = availableOptions.indexOf '/Mes photos'
        test.assert photoIndex isnt -1
        @evaluate (index) ->
            __utils__.findOne('.move-select').selectedIndex = index
        , photoIndex

    casper.thenClick 'button#modal-dialog-yes'

    casper.wait 10000

    casper.waitUntilVisible '#moved-infos button.cancel-move-btn', ->
        test.assertEval ->
            return __utils__.findAll("tr.folder-row").length is 0
        , "There shouldn't be any element"

        test.assertVisible(
            '#moved-infos button.cancel-move-btn',
            'The button to cancel the action should be visible')

        test.assertEvaluate ->
            return not __utils__.findOne('#select-all').checked
        , "The select-all checkbox should not be checked (non regression #178)"

    casper.thenClick '#moved-infos button.cancel-move-btn'

    casper.wait 10000

    casper.waitWhileVisible '.modal-dialog, .modal-backdrop', ->

        elementsNum = @evaluate -> return __utils__.findAll("tr.folder-row").length
        test.assert movedElementsNum is elementsNum, "The elements should be back"

    casper.run -> test.done()

casper.test.begin 'Bulk actions - remove all files of a folder', (test) ->

    helpers._test = test

    casper.start 'http://localhost:9121', ->

        manyFileFolderSelector = helpers.getElementSelectorByName 'Files to remove'
        test.assertEval ->
            return __utils__.findAll("tr.folder-row .fa-folder").length > 0
        , "There should must be at least one folder"

        test.assertExist manyFileFolderSelector
        test.assertVisible manyFileFolderSelector

        helpers.navigateToFolder 'Files to remove'

    casper.then ->
        movedElementsNum = @evaluate -> return __utils__.findAll("tr.folder-row").length
        test.assert movedElementsNum > 0, "There should must be at least one item"

        @click "button#select-all"

    casper.thenClick '#button-bulk-remove'

    casper.waitUntilVisible '.modal-dialog'
    # the modal has an animation
    casper.wait 500

    casper.thenClick 'button#modal-dialog-yes'

    # waits for all items to be deleted (it can be long)
    casper.waitWhileVisible 'tr.folder-row', null, null, 60000

    # waits for all the requests to be effectively processed
    casper.wait 30000, ->
        elementsNum = @evaluate -> return __utils__.findAll("tr.folder-row").length
        test.assert elementsNum is 0, "There shouldn't be any element left"

    casper.run -> test.done()

# To be implemented
casper.test.begin 'Bulk actions - move some files of a folder', (test) ->
    test.done()
casper.test.begin 'Bulk actions - remove some files of a folder', (test) ->
    test.done()
casper.test.begin 'Bulk actions - download selected files as ZIP', (test) ->
    test.done()
