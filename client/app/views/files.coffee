ViewCollection = require '../lib/view_collection'
FileView = require './file_view'

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

    initialize: (options) ->
        super options

        @itemViewOptions = ->
            isSearchMode: options.isSearchMode
            uploadQueue: options.uploadQueue

        @numSelectedElements = options.numSelectedElements

        @chevron = order: @collection.order, type: @collection.type

        @listenTo @collection, 'add remove', @updateNbFiles

        # Event delegation.
        @listenTo @collection, 'change', _.partial(@viewProxy, 'refresh')
        @listenTo @collection, 'sync error', _.partial(@viewProxy, 'onSyncError')
        @listenTo @collection, 'toggle-select', _.partial(@viewProxy, 'onToggleSelect')
        @listenTo @collection, 'add remove reset',  _.partial(@viewProxy, 'onCollectionChanged')
        @listenTo @collection, 'upload-complete',  _.partial(@viewProxy, 'onUploadComplete')


    getRenderData: ->
        _.extend super(),
            numSelectedElements: @numSelectedElements
            numElements: @collection.size()


    afterRender: ->
        super()
        @displayChevron @chevron.order, @chevron.type
        @updateNbFiles()


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
            cid = @$(object.target).parents('tr').data 'cid'

            unless cid?
                cid = @$(object.currentTarget).data 'cid'

        # Get the view.
        view = _.find @views, (view) -> view.model.cid is cid

        # In case of deletion, view may not exist anymore.
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

    # Update inherited clearance. It's useful when the folder state is changed.
    # It updates the displayed icon and the sharing state.
    updateInheritedClearance: (clearance) ->
        if clearance? and clearance.length > 0 and clearance[0].clearance?
            for file in @collection.models
                file.set 'inheritedClearance', clearance

    destroy: ->
        @stopListening @collection
        super()
