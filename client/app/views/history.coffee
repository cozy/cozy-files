ViewCollection = require 'lib/view_collection'
ContactLog = require 'models/contactlog'

module.exports = class HistoryView extends ViewCollection

    tagName: 'table'
    className: 'table-striped table-condensed table-bordered'
    template: require 'templates/history'
    itemView: require 'views/history_item'

    events: ->
        'mouseenter': 'showInjector'
        'mouseleave': 'hideInjector'
        'mouseover td': 'moveInjector'
        'click #inject-note': 'injectNote'

    afterRender: ->
        super
        @collection.fetch()
        @injector = @$('.injector').hide()

    appendView: (view) ->
        @$('tbody').append view.$el

    showInjector: -> @injector.show()
    hideInjector: -> @injector.hide()
    moveInjector: (event) ->
        tr = $(event.target).parents('tr')
        return if tr.hasClass 'injector'
        @injector.detach() if @injector.parent()
        tr.after @injector if tr.hasClass('annotable')


    injectNote: ->
        afterLog = @collection.at @injector.index() - 1
        @note = new ContactLog
            type: 'NOTE'
            direction: 'NA'
            content: ''
            timestamp: afterLog.get 'timestamp'

        @collection.add @note
        # move it after the injector (hacky)
        @injector.after @views[@note.cid].$el.detach()
        @injector.detach()

    formComplete: ->
        @injector = @clone
