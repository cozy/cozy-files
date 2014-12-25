ViewCollection = require '../lib/view_collection'
FileView = require './file'

module.exports = class FilesView extends ViewCollection
    template: require './templates/files'
    el: '#files'

    itemview: FileView
    collectionEl: '#table-items-body'

    events:
        'click #up-name'               : 'onChangeOrder'
        'click #down-name'             : 'onChangeOrder'
        'click #up-class'              : 'onChangeOrder'
        'click #down-class'            : 'onChangeOrder'
        'click #up-size'               : 'onChangeOrder'
        'click #down-size'             : 'onChangeOrder'
        'click #up-lastModification'   : 'onChangeOrder'
        'click #down-lastModification' : 'onChangeOrder'

    initialize: (options) ->
        super options

        @itemViewOptions = ->
            isSearchMode: options.isSearchMode
            uploadQueue: options.uploadQueue

        @chevron = order: @collection.order, type: @collection.type

        @listenTo @collection, 'add remove', @updateNbFiles

    afterRender: ->
        super()
        @displayChevron @chevron.order, @chevron.type
        @updateNbFiles()

    updateNbFiles: ->
        nbElements = @collection.length

        if nbElements > 0
            @$("#file-amount-indicator").html t 'element',
                smart_count: nbElements
            @$("#file-amount-indicator").show()
            @$("#no-files-indicator").hide()
        else
            @$("#file-amount-indicator").hide()
            @$("#no-files-indicator").show()

    # Helpers to display correct chevron to sort files
    displayChevron: (order, type) ->

        if order is "asc"
            @$("#up-#{type}").show()
            @$("#down-#{type}").hide()
            @$("#up-#{type}").removeClass 'unactive'
        else
            @$("#up-#{type}").hide()
            @$("#down-#{type}").show()
            @$("#down-#{type}").removeClass 'unactive'


    # Changer sorting depending on the clicked chevron.
    onChangeOrder: (event) ->
        [order, type] = event.target.id.split '-'

        order = if order is 'up' then 'desc' else 'asc'

        @chevron = order: order, type: type
        @collection.order = order
        @collection.type = type
        @collection.sort()

    updateInheritedClearance: (clearance) ->
        if clearance? and clearance.length > 0 and clearance[0].clearance?
            for file in @collection.models
                file.set 'inheritedClearance', clearance

    destroy: ->
        @stopListening @collection
        super()
