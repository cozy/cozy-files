#ViewCollection = require '../lib/view_collection'
BaseView = require '../lib/base_view'
FileView = require './file_view'
LongList = require '../lib/long-list-rows'

module.exports = class FilesView extends BaseView #ViewCollection
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

        # Event delegation.
        'click a.file-tags': (e) -> @viewProxy 'onTagClicked', e
        'click a.file-delete': (e) -> @viewProxy 'onDeleteClicked', e
        'click a.file-share': (e) -> @viewProxy 'onShareClicked', e
        'click a.file-edit': (e) -> @viewProxy 'onEditClicked', e
        'click a.file-edit-save': (e) -> @viewProxy 'onSaveClicked', e
        'click a.file-edit-cancel': (e) -> @viewProxy 'onCancelClicked', e
        'click a.cancel-upload-button': (e) -> @viewProxy 'onCancelUploadClicked', e
        'click a.file-move': (e) -> @viewProxy 'onMoveClicked', e
        'click a.broken-button': (e) -> @viewProxy 'onDeleteClicked', e
        'keydown input.file-edit-name': (e) -> @viewProxy 'onKeyPress', e
        'click div.selector-wrapper button': (e) -> @viewProxy 'onSelectClicked', e
        'click div.link-wrapper i.fa': (e) -> @viewProxy 'onSelectClicked', e
        'click tr.folder-row': (e) -> @viewProxy 'onLineClicked', e
        'click li.itemRow': (e) -> @viewProxy 'onLineClicked', e

    initialize: (options) ->
        super options

        @itemViewOptions = ->
            isSearchMode: options.isSearchMode
            uploadQueue: options.uploadQueue

        @numSelectedElements = options.numSelectedElements

        @chevron = order: @collection.order, type: @collection.type

        @listenTo @collection, 'add', @addFile
        @listenTo @collection, 'remove', @removeFile

        # Event delegation.
        @listenTo @collection, 'change', _.partial(@viewProxy, 'refresh')
        @listenTo @collection, 'sync error', _.partial(@viewProxy, 'onSyncError')
        @listenTo @collection, 'toggle-select', _.partial(@viewProxy, 'onToggleSelect')
        @listenTo @collection, 'add remove reset',  _.partial(@viewProxy, 'onCollectionChanged')
        @listenTo @collection, 'upload-complete',  _.partial(@viewProxy, 'onUploadComplete')



    addFile: (model, collection, options) ->
        @longList.addRow(collection.indexOf(model))
        @updateNbFiles()


    removeFile: (model, collection, options) ->
        @longList.removeRow(options.index)
        @updateNbFiles()


    getRenderData: ->
        _.extend super(),
            numSelectedElements: @numSelectedElements
            numElements: @collection.size()


    beforeRender: ->
        super()
        @startPoint = performance.now()


    afterRender: ->
        super()
        @displayChevron @chevron.order, @chevron.type
        @updateNbFiles()

        # Pool of views that matches the buffer of elements of LongList.
        @pool = []

        # LongList options.
        options =
            # unit used for the dimensions (px,em or rem)
            DIMENSIONS_UNIT : 'px' #'em'

            # Height reserved for each row (unit defined by DIMENSIONS_UNIT)
            ROW_HEIGHT      : 37 #2

            # number of "screens" before and after the viewport
            # (ex : 1.5 => 1+2*1.5=4 screens always ready)
            BUFFER_COEF   : 4

            # number of "screens" before and after the viewport corresponding to
            # the safe zone. The Safe Zone is the rows where viewport can go
            # without trigering the movement of the buffer.
            # Must be smaller than BUFFER_COEFF
            SAFE_ZONE_COEF  : 3

            # minimum duration between two refresh after scroll (ms)
            THROTTLE        : 150

            # max number of viewport height by seconds : beyond this speed the
            # refresh is delayed to the nex throttle
            MAX_SPEED       : 2.5

            # call back when a row of the buffer is moved and must be completly
            # redecorated
            onRowsMovedCB   : @onRowsMoved.bind(@)

        # DOM element the LongList will be bound to.
        viewPortElement = @$(@collectionEl)[0]

        # Initialize the list.
        @longList = new LongList viewPortElement, options
        @longList.initRows @collection.length


    # Handler called when the list must update.
    onRowsMoved: (rowsToDecorate) ->

        for row, index in rowsToDecorate
            if row.el
                rank = row.rank
                if row.el.view?
                    model = @collection.at rank
                    if model
                        model.rank = rank
                        view = row.el.view
                        view.model = model
                        view.reDecorate()

                else
                    model = @collection.at rank
                    model.rank = rank
                    options = _.extend {}, {model}, @itemViewOptions()
                    view = new FileView options
                    view.setElement row.el
                    view.render()

                    row.el.view = view
                    @pool.push view

        return true


    # Manage event delegation. Events are listen to on the collection level,
    # then the callback are called on the view that originally triggered them.
    #
    # * `methodName` is the method that will be called on the View.
    # * `object` can be a File model or a DOMElement within FileView.$el
    viewProxy: (methodName, object) ->

        # Get view's cid. Views are indexed by cid. Object can be a File model
        # or a DOMElement within FileView.$el.
        if object.cid?
            cid = object.cid
        else
            cid = @$(object.target).parents('li').data 'cid'

            unless cid?
                cid = @$(object.currentTarget).data 'cid'

        # Get the view.
        view = _.find @pool, (view) -> view.model.cid is cid

        # In case of deletion, view may not exist anymore.
        # If model isn't attached to a view in the pool, it is not found.
        if view?
            # Call `methodName` on the related view.
            args = [].splice.call arguments, 1
            view[methodName].apply view, args



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
            @$("#up-#{type}").addClass 'active'
            @$("#down-#{type}").hide()
            @$("#up-#{type}").removeClass 'unactive'
        else
            @$("#up-#{type}").hide()
            @$("#down-#{type}").addClass 'active'
            @$("#down-#{type}").removeClass 'unactive'


    # Changer sorting depending on the clicked chevron.
    onChangeOrder: (event) ->
        [order, type] = event.target.id.split '-'

        order = if order is 'up' then 'desc' else 'asc'

        @chevron = order: order, type: type
        @collection.order = order
        @collection.type = type
        @collection.sort()

    # Update inherited clearance. It's useful when the folder state is changed.
    # It updates the displayed icon and the sharing state.
    updateInheritedClearance: (clearance) ->
        if clearance? and clearance.length > 0 and clearance[0].clearance?
            for file in @collection.models
                file.set 'inheritedClearance', clearance

    destroy: ->
        @stopListening @collection
        super()
