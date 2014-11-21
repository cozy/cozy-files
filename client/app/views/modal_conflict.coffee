Modal = require "./modal"
client = require "../lib/client"

module.exports = class ModalConflictView extends Modal

    conflictTemplate: ->
        rememberLabel = t 'overwrite modal remember label'
        return """
            <div class="move-widget">
            <p>#{t 'overwrite modal content', fileName: @model.get 'name'}</p>
            <p>
                <label for="rememberChoice">#{rememberLabel}</label>
                <input id="rememberChoice" type="checkbox"/>
            </p>
            </div>
    """

    constructor: (@model, @callback) ->
        super t('overwrite modal title'), '', \
              t('overwrite modal yes button'), \
              t('overwrite modal no button'), \
              @confirmCallback

    confirmCallback: (confirm) ->
        rememberChoice = @$('#rememberChoice').prop 'checked'
        rememberedChoice = confirm if rememberChoice
        @callback confirm, rememberedChoice

    afterRender: ->
        @conflictForm = $ @conflictTemplate()
        @$el.find('.modal-body').append @conflictForm

