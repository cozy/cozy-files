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

    afterRender: ->
        @$el.modal 'show'

    getRenderData: ->
        _.extend {}, @model.attributes, @getNames()

    save: ->
        fields = ['last', 'first', 'middle', 'prefix', 'suffix']

        @model.set 'n', fields.map (field) -> $('#' + field).val()
        @options.onChange()
        @close()

    close: =>
        @$el.modal 'hide'
        @$el.on 'hidden', => @remove()


    # NAME MANAGEMENT

    initials =  (middle) ->
        if i = value.split(/[ \,]/)[0][0]?.toUpperCase() then i + '.'
        else ''


    getNames: ->
        out = @model.pick 'n', 'fn'
        if out.fn and not out.n
            out.n = @getComputedN()
        else if out.n and not out.fn
            out.fn = @getComputedFN()

        return out

    getComputedFN: (n) ->
        [familly, given, middle, prefix, suffix] = @model.get 'n'
        switch app.config.get 'nameOrder'
            when 'given-familly'
                "#{given} #{familly}"

            when 'given-middleinitial-familly'
                "#{given} #{initial(middle)} #{familly}"

            when 'familly-given'
                "#{familly}, #{given} #{middle}"

    getComputedN: (n) ->
        familly = given = middle = prefix = suffix = ""
        parts = fn.split(/[ \,]/).filter (part) -> part isnt ""
        switch app.config.get 'nameOrder'
            when 'given-familly'
                given = fn[0]
                familly = fn[1]
            when 'given-middleinitial-familly'
                given = fn[0]
                familly = fn[fn.length-1]
                middle = fn[1..fn.length-2].join(' ')
            when 'familly-given'
                familly = fn[0]
                given = fn[1]
                middle = fn[2..].join(' ')

        return [familly, given, middle, prefix, suffix]