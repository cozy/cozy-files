ViewCollection = require 'lib/view_collection'
Datapoint = require 'models/datapoint'


module.exports = class ContactView extends ViewCollection

    id: 'contact'
    template: require 'templates/contact'
    itemView: require 'views/datapoint'

    events: ->
        'click .addbirthday': @addClicked 'about', 'birthday'
        'click .addcompany' : @addClicked 'about', 'org'
        'click .addtitle'   : @addClicked 'about', 'title'
        'click .addabout'   : @addClicked 'about'
        'click .addtel'     : @addClicked 'tel'
        'click .addemail'   : @addClicked 'email'
        'click .addadr'     : @addClicked 'adr'
        'click .addother'   : @addClicked 'other'
        'click .addurl'     : @addClicked 'url'
        'click #save'       : 'save'
        'click #delete'     : 'delete'
        'blur .value'       : 'cleanup'
        'keypress #name'    : 'changeOccured'
        'keypress #notes'   : 'changeOccured'
        'change #uploader'  : 'photoChanged'


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
        for type in ['about', 'email', 'adr', 'tel', 'url', 'other']
            @zones[type] = @$('#' + type + 's ul')

        @hideEmptyZones()
        @spinner =    @$('#spinOverlay')
        @saveButton = @$('#save').addClass('disabled').text 'saved'
        @needSaving = false
        @namefield = @$('#name')
        @notesfield = @$('#notes')
        @uploader = @$('#uploader')[0]
        @picture  = @$('#picture .picture')

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

    changeOccured: ->
        @saveButton.removeClass('disabled').text 'save'
        @needSaving = true

    modelChanged: ->
        @namefield.val  @model.get 'fn'
        @notesfield.val @model.get 'note'

    delete: ->
        @model.destroy()

    cleanup: ->
        @model.dataPoints.prune()
        @hideEmptyZones()

    save: =>
        return unless @needSaving
        @cleanup()
        @needSaving = false
        @model.save
            fn:  @namefield.val()
            note: @notesfield.val()

    onRequest: ->
        @spinner.show()

    onSuccess: ->
        @spinner.hide()
        @saveButton.addClass('disabled').text 'saved'

    onError: ->
        @spinner.hide()

    photoChanged: () =>

        file = @uploader.files[0]

        unless file.type.match /image\/.*/
            return alert 'This is not an image'

        reader = new FileReader()
        img = new Image()
        reader.readAsDataURL file
        reader.onloadend = =>
            img.src = reader.result
            img.onload = =>
                ratiodim = if img.width > img.height then 'height' else 'width'
                ratio = 64 / img[ratiodim]

                # use canvas to resize the image
                canvas = document.createElement 'canvas'
                canvas.height = canvas.width = 64
                ctx = canvas.getContext '2d'
                ctx.drawImage img, 0, 0, ratio*img.width, ratio*img.height
                dataUrl =  canvas.toDataURL 'image/jpeg'

                @picture.attr 'src', dataUrl

                #transform into a blob
                binary = atob dataUrl.split(',')[1]
                array = []
                for i in [0..binary.length]
                    array.push binary.charCodeAt i

                blob = new Blob [new Uint8Array(array)], type: 'image/jpeg'

                @model.picture = blob
                @changeOccured()


