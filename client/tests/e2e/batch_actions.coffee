
__utils__ = require('clientutils').create()

helpers = require('../helpers')(casper, __utils__)

casper.options.viewportSize = width: 1280, height: 800

firstElement = "tr.folder-row:first-of-type"
elementIcon = "#{firstElement} .fa.fa-folder"
elementCheckbox = "#{firstElement} input.selector"
allCheckedInList = "tr.folder-row input.selector:checked"

casper.test.begin 'Batch actions - select all', (test) ->

    casper.start 'http://localhost:9121', ->

        test.assertTitle 'Cozy - Files', 'Checks that application is properly started'
        test.assertNotVisible '#button-bulk-move', "'Move all' button shouldn't be visible"
        test.assertNotVisible '#button-bulk-remove', "'Remove all' button shouldn't be visible"

        test.assertVisible 'input#select-all', 'The select all button should be visible'

    casper.thenClick 'input#select-all'

    casper.waitUntilVisible '#button-bulk-move, #button-bulk-remove', ->

        test.assertEval -> return __utils__.findOne('input#select-all').checked
        test.assertVisible '#button-bulk-move', "'Move all' button should be visible"
        test.assertVisible '#button-bulk-remove', "'Remove all' button should be visible"

    casper.thenClick 'input#select-all'

    casper.waitWhileVisible '#button-bulk-move, #button-bulk-remove', ->
        test.assertEval -> return not __utils__.findOne('input#select-all').checked
        test.assertNotVisible '#button-bulk-move', "'Move all' button shouldn't be visible"
        test.assertNotVisible '#button-bulk-remove', "'Remove all' button shouldn't be visible"

    casper.run  -> test.done()


casper.test.begin 'Batch actions - checkbox toggle display on mouseover/out', (test) ->

    casper.start 'http://localhost:9121', ->
        test.assertExist 'tr.folder-row', 'There should be elements in the list'
        test.assertNotVisible 'input.selector', "No checkbox should be visible"

    casper.then -> @mouse.move elementIcon

    casper.waitUntilVisible elementCheckbox, ->
        test.assertVisible elementCheckbox, "The checkbox should be visible"

    casper.then -> @mouse.move 0, 0

    casper.waitWhileVisible elementCheckbox, ->
        test.assertNotVisible elementCheckbox, "The checkbox shouldn't be visible"

    casper.run  -> test.done()


casper.test.begin 'Batch actions - select one item', (test) ->

    casper.start 'http://localhost:9121', ->
        test.assertExist 'tr.folder-row', 'There should be elements in the list'
        test.assertNotVisible '#button-bulk-move', "'Move all' button shouldn't be visible"
        test.assertNotVisible '#button-bulk-remove', "'Remove all' button shouldn't be visible"
        test.assertNotVisible 'input.selector', "No checkbox should be visible"
        test.assertElementCount allCheckedInList, 0, "No checkbox should be checked"

    casper.thenClick elementCheckbox

    casper.waitUntilVisible '#button-bulk-move, #button-bulk-remove', ->
        test.assertVisible '#button-bulk-move', "'Move all' button should be visible"
        test.assertVisible '#button-bulk-remove', "'Remove all' button should be visible"

    casper.run  -> test.done()


casper.test.begin 'Batch actions - selecting 3 items checks the "select-all" checkbox', (test) ->

    casper.start 'http://localhost:9121', ->
        test.assertExist 'tr.folder-row', 'There should be elements in the list'
        test.assertExist 'input#select-all', 'The select all button should be visible'
        test.assertElementCount allCheckedInList, 0, "No checkbox should be checked"

    casper.then ->
        for i in [1..2] by 1
            @click ".folder-row:nth-of-type(#{i}) input.selector"

    casper.then -> test.assertDoesntExist '#select-all:checked', "'Select all' checkbox shouldn't be checked"

    casper.thenClick ".folder-row:nth-of-type(3) input.selector"

    casper.then -> test.assertExist '#select-all:checked', "'Select all' checkbox should be checked"

    casper.run -> test.done()


casper.test.begin 'Batch actions - selecting all items when there are least than 3 items, should check the "select all" checkbox (non regression)', (test) ->

    casper.start 'http://localhost:9121', ->

        imageFolderSelector = helpers.getElementSelectorByName 'Mes images'
        test.assertExist imageFolderSelector
        test.assertVisible imageFolderSelector

        helpers.navigateToFolder 'Mes images'

    casper.then ->

        test.assertExist 'input#select-all', 'The select all button should be visible'
        test.assertElementCount allCheckedInList, 0, "No checkbox should be checked"

        itemsNum = @evaluate ->
            return __utils__.findAll("tr.folder-row").length

        test.assert (0 < itemsNum < 3), "There should be strictly between 1 and 3 items"

    casper.thenClick "input#select-all"

    casper.then ->
        test.assertEvaluate ->
            return __utils__.findOne('#select-all').checked
        , "The select-all checkbox should be checked"

    casper.run -> test.done()

casper.test.begin 'Batch actions - move all files to a folder', (test) ->

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

        movedElementsNum = @evaluate -> return __utils__.findAll("tr.folder-row").length
        test.assert movedElementsNum > 0, "There should must be at least one item"

        @click "input#select-all"

    casper.thenClick '#button-bulk-move'

    casper.waitUntilVisible '.modal-dialog'
    # the modal has an animation
    casper.wait 500, ->
        availableOptions = @evaluate ->
            options = __utils__.findAll '.move-select option'
            return Array::map.call options, (option) -> return option.textContent

        photoIndex = availableOptions.indexOf '/Mes photos'
        test.assert photoIndex isnt -1
        @evaluate (index) ->
            __utils__.findOne('.move-select').selectedIndex = index
        , photoIndex

    casper.thenClick 'button#modal-dialog-yes'

    casper.waitUntilVisible '#moved-infos button.cancel-move-btn', ->

        test.assertEval ->
            return __utils__.findAll("tr.folder-row").length is 0
        , "There shouldn't be any element"

        test.assertVisible '#moved-infos button.cancel-move-btn', 'The button to cancel the action should be visible'

        test.assertEvaluate ->
            return not __utils__.findOne('#select-all').checked
        , "The select-all checkbox should not be checked (non regression #178)"

    casper.thenClick '#moved-infos button.cancel-move-btn'

    casper.waitWhileVisible '.modal-dialog, .modal-backdrop', ->

        elementsNum = @evaluate -> return __utils__.findAll("tr.folder-row").length
        test.assert movedElementsNum is elementsNum, "The elements should be back"

    casper.run -> test.done()

casper.test.begin 'Batch actions - remove all files of a folder', (test) ->

    casper.start 'http://localhost:9121', ->

        manyFileFolderSelector = helpers.getElementSelectorByName 'Many files'
        test.assertEval ->
            return __utils__.findAll("tr.folder-row .fa-folder").length > 0
        , "There should must be at least one folder"

        test.assertExist manyFileFolderSelector
        test.assertVisible manyFileFolderSelector

        helpers.navigateToFolder 'Many files'

    casper.then ->
        movedElementsNum = @evaluate -> return __utils__.findAll("tr.folder-row").length
        test.assert movedElementsNum > 0, "There should must be at least one item"

        @click "input#select-all"

    casper.thenClick '#button-bulk-remove'

    casper.waitUntilVisible '.modal-dialog'
    # the modal has an animation
    casper.wait 500

    casper.thenClick 'button#modal-dialog-yes'

    # waits for all items to be deleted (it can be long)
    casper.waitWhileVisible 'tr.folder-row', null, null, 70000

    # waits for all the requests to be effectively processed
    casper.wait 5000, ->
        elementsNum = @evaluate -> return __utils__.findAll("tr.folder-row").length
        test.assert elementsNum is 0, "There shouldn't be any element left"
        @capture 'debug.png'

    casper.run ->
        test.done()
