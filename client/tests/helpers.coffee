module.exports = (casper, utils) -> helpers =

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

        return "tr.folder-row:nth-of-type(#{index + 1})"

    navigateToFolder: (folderName) ->

        casper.click "#{helpers.getElementSelectorByName folderName} a.btn-link"
        casper.waitForUrl /#folders\/[a-z0-9]+/
        casper.waitForSelector 'tr.folder-row'

