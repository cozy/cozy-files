ViewCollection = require '../lib/view_collection'
FileView = require './file'

module.exports = class FilesView extends ViewCollection
    template: require './templates/files'
    el: '#files'

    itemview: FileView
    collectionEl: '#table-items-body'

    events:
        'click [aria-sort] a':          'onChangeOrder'

        # file view events
        'click a.file-tags':            (e) -> @viewProxy 'onTagClicked', e
        'click a.file-delete':          (e) -> @viewProxy 'onDeleteClicked', e
        'click a.file-share':           (e) -> @viewProxy 'onShareClicked', e
        'click a.file-edit':            (e) -> @viewProxy 'onEditClicked', e
        'click a.file-edit-save':       (e) -> @viewProxy 'onSaveClicked', e
        'click a.file-edit-cancel':     (e) -> @viewProxy 'onCancelClicked', e
        'click a.file-move':            (e) -> @viewProxy 'onMoveClicked', e
        'keydown input.file-edit-name': (e) -> @viewProxy 'onKeyPress', e
        'change input.selector':        (e) -> @viewProxy 'onSelectChanged', e


    initialize: (options) ->
        super options

        @itemViewOptions = ->
            isSearchMode: options.isSearchMode
            uploadQueue: options.uploadQueue

        @chevron = order: @collection.order, type: @collection.type

        @listenTo @collection, 'add remove', @updateNbFiles
        @listenTo @collection, 'change',
                               _.partial @viewProxy, 'refresh'
        @listenTo @collection, 'request',
                               _.partial @viewProxy, 'onRequest'
        @listenTo @collection, 'sync error',
                               _.partial @viewProxy, 'onSyncError'
        @listenTo @collection, 'toggle-select',
                               _.partial @viewProxy, 'onToggleSelect'

    afterRender: ->
        super()
        @displayChevron @chevron.order, @chevron.type
        @updateNbFiles()


    viewProxy: (methodName, obj) ->
        cid = if obj.cid? then obj.cid else
                               @$(obj.target).parents('tr').data('cid')

        view = _.find @views, (view) -> view.model.cid is cid
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
        $parentEl = @$ ".#{type}"
        $parentEl.attr 'aria-sort', "#{order}ending"

        if order is "asc"
            $parentEl.find("#up-#{type}").show()
            $parentEl.find("#down-#{type}").hide()
            $parentEl.find("#up-#{type}").removeClass 'unactive'
        else
            $parentEl.find("#up-#{type}").hide()
            $parentEl.find("#down-#{type}").show()
            $parentEl.find("#down-#{type}").removeClass 'unactive'


    # Changer sorting depending on the clicked chevron.
    onChangeOrder: (event) ->
        [order, type] = event.target.id.split '-'

        order = if order is 'up' then 'desc' else 'asc'

        @chevron = order: order, type: type
        @collection.order = order
        @collection.type = type
        @collection.sort()

        @$("[aria-sort]:not('.#{type}')").attr 'aria-sort', 'none'

    # Update inherited clearance. It's useful when the folder state is changed.
    # It updates the displayed icon and the sharing state.
    updateInheritedClearance: (clearance) ->
        if clearance? and clearance.length > 0 and clearance[0].clearance?
            for file in @collection.models
                file.set 'inheritedClearance', clearance

    destroy: ->
        @stopListening @collection
        super()
