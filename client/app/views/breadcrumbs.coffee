BaseView = require '../lib/base_view'
ModalShareView = require './modal_share'

module.exports = class BreadcrumbsView extends BaseView

    itemview: require './templates/breadcrumbs_element'
    tagName: "ul"

    events:
        'click .share-state': 'onShareClicked'

    constructor: (@collection) ->
        super()

    initialize: ->
        @listenTo @collection, "reset",   @render
        @listenTo @collection, "add",     @render
        @listenTo @collection, "remove",  @render


    onShareClicked: ->
        return unless @collection.length > 1
        lastModel = @collection.at @collection.length - 1
        @listenTo lastModel, 'change', @render
        new ModalShareView model: lastModel

    render: ->
        @$el.html ""
        for folder in @collection.models
            @$el.append @itemview(model: folder)

        if @collection.length > 1
            shareState = $ '<li class="share-state"></li>'
            clearance = folder.get 'clearance'
            if clearance is 'public'
                shareState.append $ '<span class="fa fa-globe"></span>'
            else if clearance and clearance.length > 0
                shareState.append $ "<span class='fa fa-users'>" \
                                    + "#{clearance.length}</span>"
            else
                shareState.append $ '<span class="fa fa-lock"></span>'
            @$el.append shareState
        @
