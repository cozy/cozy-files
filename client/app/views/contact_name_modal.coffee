BaseView       = require 'lib/base_view'
CallLogReader  = require 'lib/call_log_reader'
ContactLogCollection = require 'collections/contactlog'
app            = require 'application'

module.exports = class CallImporterView extends BaseView

    template: require 'templates/name_modal'

    id: 'namemodal'
    tagName: 'div'
    className: 'modal fade'

    events:
        'click #cancel-btn': 'close'
        'click #confirm-btn': 'save'
        'change input': 'refreshFN'

    afterRender: ->
        @$el.modal 'show'

    getRenderData: ->
        _.extend {}, @model.attributes,
            fn: @model.getFN()
            n: @model.get('n') or @model.getComputedN()

    getStructuredName: ->
        fields = ['last', 'first', 'middle', 'prefix', 'suffix']
        return fields.map (field) -> $('#' + field).val()

    save: ->
        @model.set 'n', @getStructuredName()
        @model.set 'fn', ''
        @options.onChange()
        @close()

    refreshFN: ->
        @$('#full').val @model.getComputedFN @getStructuredName()

    close: =>
        @$el.modal 'hide'
        @$el.on 'hidden', => @remove()