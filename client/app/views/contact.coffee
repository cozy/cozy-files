ViewCollection = require 'lib/view_collection'
Datapoint = require 'models/datapoint'


module.exports = class ContactView extends ViewCollection

    id: 'contact'
    template: require 'templates/contact'
    itemView: require 'views/datapoint'

    events: ->
        'click .addbirthday': @addClicked 'about', 'birthday'
        'click .addcompany' : @addClicked 'about', 'company'
        'click .addabout'   : @addClicked 'about'
        'click .addphone'   : @addClicked 'phone'
        'click .addemail'   : @addClicked 'email'
        'click .addsmail'   : @addClicked 'smail'
        'click .addother'   : @addClicked 'other'
        'click #save'       : @save
        'click #delete'     : @delete
        'blur .value'       : @cleanup
        'keypress #name'    : @changeOccured
        'keypress #notes'   : @changeOccured

    constructor: (options) ->
        options.collection = options.model.dataPoints
        super

    initialize: ->
        super
        @listenTo @model,      'change' , @modelChanged
        @listenTo @model,      'destroy', @modelDestroyed
        @listenTo @model,      'request', @onRequest
        @listenTo @model,      'error',   @onError
        @listenTo @model,      'sync',    @onSuccess

        @listenTo @collection, 'change' , @changeOccured

    getRenderData: -> @model.toJSON()

    afterRender: ->
        @zones = {}
        for type in ['about', 'email', 'smail', 'phone', 'other']
            @zones[type] = @$('#' + type + 's ul')

        @hideEmptyZones()
        @spinner =    @$('#spinOverlay')
        @saveButton = @$('#save').addClass('disabled').text 'saved'
        @needSaving = false
        @namefield = @$('#name')
        @notesfield = @$('#notes')

        super

    hideEmptyZones: ->
        for type, zone of @zones
            zone.parent().toggle @model.dataPoints.hasOne type

    appendView: (dataPointView) ->
        return unless @zones
        type = dataPointView.model.get 'name'
        @zones[type].append dataPointView.el
        @hideEmptyZones()

    addClicked: (name, type) -> (event) ->
        event.preventDefault()
        point = new Datapoint name: name
        point.set 'type', type if type?
        @model.dataPoints.add point
        @zones[name].children().last().find('.type').focus()

    cleanup: ->
        @model.dataPoints.prune()
        @hideEmptyZones()

    changeOccured: ->
        @saveButton.removeClass('disabled').text 'save'
        @needSaving = true

    modelChanged: ->
        @namefield.val @model.get 'name'
        @notesfield.val @model.get 'notes'

    delete: ->
        @model.destroy()

    save: =>
        return unless @needSaving
        @needSaving = false
        @model.save
            name:  @namefield.val()
            notes: @notesfield.val()

    onRequest: ->
        @spinner.show()

    onSuccess: ->
        @spinner.hide()
        @saveButton.addClass('disabled').text 'saved'

    onError: ->
        @spinner.hide()