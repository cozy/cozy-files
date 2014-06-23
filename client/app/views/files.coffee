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

        @itemViewOptions = -> isSearchMode: options.isSearchMode
        @chevron = order: @collection.order, type: @collection.type

        @listenTo @collection, "add", @render
        @listenTo @collection, "remove", @render
        @listenTo @collection, "sort", @render
        @listenTo @collection, "reset", @render

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

        if order is "down"
            @$("#up-#{type}").show()
            @$("#down-#{type}").hide()
            @$("#up-#{type}").removeClass 'unactive'
        else
            @$("#up-#{type}").hide()
            @$("#down-#{type}").show()
            @$("#down-#{type}").removeClass 'unactive'


    # Changer sorting depending on the clicked chevron.
    onChangeOrder: (event) ->
        infos = event.target.id.split '-'
        order = infos[0]
        type = infos[1]

        @chevron = order: order, type: type

        order = if order is 'down' then 'decr' else 'incr'
        @collection.order = order
        @collection.type = type
        @collection.sort()
