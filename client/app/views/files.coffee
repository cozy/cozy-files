ViewCollection = require '../lib/view_collection'
FileView = require './file'
ModalShareView = null


minHeight = 45


module.exports = class FilesView extends ViewCollection
    template: require './templates/files'
    el: '#files'

    itemview: FileView
    collectionEl: 'tbody#table-items-body'

    events:
        'click [aria-sort] a':          'onChangeOrder'

        # file view events
        'click a.file-tags':            'onTagClicked'
        'click a.file-share':           'onShareClicked'
        'click a.file-edit':            'onEditClicked'
        'click a.file-edit-save':       'onSaveClicked'
        'click a.file-edit-cancel':     'onCancelClicked'
        'change input.selector':        'onSelectChanged'


    initialize: (options) ->
        @lastIndexPosition = 0
        @lastTopPosition = 0
        @itemViewOptions = =>
            isSearchMode: options.isSearchMode
            uploadQueue: options.uploadQueue
            collection: @

        @collectionEl = el unless @collectionEl?
        @chevron = order: @collection.order, type: @collection.type

        window.addEventListener 'scroll', _.debounce(@onScroll, 35)
        $(document).on 'keydown.fileedit', _.bind(@onKeyDown, @)

        @listenTo @collection, 'add remove', @updateNbFiles
        @listenTo @collection, 'change', @refresh
        @listenTo @collection, 'request', @onRequest
        @listenTo @collection, 'sync error', @onSyncError
        @listenTo @collection, 'toggle-select', @onToggleSelect


    isIndexInViewport: (index) ->
        top = index * minHeight + @collectionNode.getBoundingClientRect().top
        viewportBottom = window.pageYOffset + window.innerHeight
        delta = minHeight * 20
        top >= (window.pageYOffset - delta) and top < (viewportBottom + delta)


    getViewFromModel: (model) ->
        _.find @views, (view) -> view.model.cid is model.cid


    render: ->
        super
        # add 'empty' class to view when there is no subview
        @$el.toggleClass 'empty', @collectionVTree.children.length


    beforeRender: ->
        @newCollectionVTree = virtualDom.h @collectionEl


    afterRender: ->
        unless @collectionNode?
            @collectionVTree = virtualDom.h @collectionEl
            @collectionNode = virtualDom.create @collectionVTree
            @el.querySelector('#table-items').appendChild @collectionNode

        @onReset @collection
        @displayChevron @chevron.order, @chevron.type
        @updateNbFiles()


    addItem: (model) =>
        options = _.extend {}, model: model, @itemViewOptions(model)
        @appendView new @itemview options


    # event listeners for remove
    removeItem: (model) =>
        item = @getViewFromModel model
        @views.splice _.indexOf(@views, item), 1

        @onChange @views


    # we append the views at a specific index
    # based on their order in the collection
    appendView: (view) ->
        index = @views.push view
        view.render @isIndexInViewport --index
        @newCollectionVTree.children.push view.elVTree
        return view


    refresh: (obj) ->
        if obj?
            view  = @getViewFromModel(obj) || @addItem(obj)
            view.render()

        else
            patches = virtualDom.diff @collectionVTree, @newCollectionVTree
            @collectionNode = virtualDom.patch @collectionNode, patches
            @collectionVTree = @newCollectionVTree
            _.invoke @views, 'afterRender'


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


    # event listener for reset
    onReset: (newcollection) ->
        newcollection.forEach @addItem
        @refresh()


    # Changer sorting depending on the clicked chevron.
    onChangeOrder: (event) ->
        [order, type] = event.target.id.split '-'

        order = if order is 'up' then 'desc' else 'asc'

        @chevron = order: order, type: type
        @collection.order = order
        @collection.type = type
        @collection.sort()

        @$("[aria-sort]:not('.#{type}')").attr 'aria-sort', 'none'


    onRequest: (model) ->
        @$("[data-vdom=#{model.cid}] .spinholder").show()
        @$("[data-vdom=#{model.cid}] .icon-zone .fa").addClass 'hidden'


    onSyncError: (model) ->
        @getViewFromModel(model).render() if model.conflict
        @$("[data-vdom=#{model.cid}] .spinholder").hide()
        @$("[data-vdom=#{model.cid}] .icon-zone .fa").removeClass 'hidden'


    @onToggleSelect: (model) ->
        @$("[data-vdom=#{model.cid}]")
        .toggleClass 'selected', model.isSelected
        .find 'input.selector'
            .prop 'checked', model.isSelected


    # Ui events
    onKeyDown: (event) ->
        editedView = _.findWhere @views, isEditMode: true
        return unless editedView?

        if event.keyCode is 27
            editedView.toggleEditMode false
        if event.keyCode is 13
            editedView.saveEdit()


    onTagClicked: (event) ->
        cid = @$(event.currentTarget).parents('tr[data-vdom]').data('vdom')
        @getViewFromModel(cid: cid).tags.toggleInput()


    onShareClicked: (event) ->
        if app.isPublic then return
        ModalShareView ?= require "./modal_share"
        cid = @$(event.currentTarget).parents('tr[data-vdom]').data('vdom')
        new ModalShareView model: @collection.get(cid)


    onEditClicked: (event) ->
        editedView = _.findWhere @views, isEditMode: true
        editedView.toggleEditMode(false) if editedView?

        $el  = @$(event.currentTarget).parents('tr[data-vdom]')
        view = @getViewFromModel cid: $el.data('vdom')
        view.toggleEditMode(true)


    onSaveClicked: ->
        editedView = _.findWhere @views, isEditMode: true
        editedView.saveEdit() if editedView?


    onCancelClicked: ->
        editedView = _.findWhere @views, isEditMode: true
        editedView.toggleEditMode(false) if editedView?


    onScroll: =>
        minHeight = @views[0].el.offsetHeight
        startRendering = false

        if window.pageYOffset > @lastTopPosition
            range = [@lastIndexPosition...@views.length]
        else
            range = [@lastIndexPosition..0]

        for index in range
            if startRendering and not @isIndexInViewport index
                @lastTopPosition = window.pageYOffset
                @lastIndexPosition = index
                break
            if @isIndexInViewport index
                startRendering = true
                @views[index].render()


    # Update inherited clearance. It's useful when the folder state is changed.
    # It updates the displayed icon and the sharing state.
    updateInheritedClearance: (clearance) ->
        if clearance? and clearance.length > 0 and clearance[0].clearance?
            for file in @collection.models
                file.set 'inheritedClearance', clearance


    destroy: ->
        @stopListening @collection
        super
