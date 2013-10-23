ViewCollection = require 'lib/view_collection'
HistoryView = require 'views/history'
TagsView = require 'views/contact_tags'
Datapoint = require 'models/datapoint'


module.exports = class ContactView extends ViewCollection

    id: 'contact'
    template: require 'templates/contact'
    itemView: require 'views/datapoint'

    events: ->
        'click .addbirthday': @addClicked 'about', 'birthday'
        'click .addorg' : @addClicked 'about', 'org'
        'click .addtitle'   : @addClicked 'about', 'title'
        'click .addcozy'    : @addClicked 'about', 'cozy'
        'click .addabout'   : @addClicked 'about'
        'click .addtel'     : @addClicked 'tel'
        'click .addemail'   : @addClicked 'email'
        'click .addadr'     : @addClicked 'adr'
        'click .addother'   : @addClicked 'other'
        'click .addurl'     : @addClicked 'url'
        'click #undo'       : 'undo'
        'click #delete'     : 'delete'
        'keyup .type'       : 'onKeyUp'
        'keyup .value'      : 'onKeyUp'
        'keyup #notes'      : 'resizeNote'
        'change #uploader'  : 'photoChanged'

        'keypress .type'    : 'changeOccured'
        'keypress #name'    : 'changeOccured'
        'change #name'      : 'changeOccured'
        'keypress #notes'   : 'changeOccured'
        'change #notes'     : 'changeOccured'


    constructor: (options) ->
        options.collection = options.model.dataPoints
        @saveLater = _.debounce @save, 3000
        super

    initialize: ->
        super
        @listenTo @model     , 'change' , @modelChanged
        @listenTo @model     , 'request', @onRequest
        @listenTo @model     , 'error'  , @onError
        @listenTo @model     , 'sync'   , @onSuccess
        @listenTo @collection, 'change' , @changeOccured
        @listenTo @collection, 'add' , @changeOccured
        @listenTo @collection, 'remove' , @changeOccured

    getRenderData: ->
        _.extend {}, @model.toJSON(), hasPicture: @model.hasPicture or false

    afterRender: ->
        @zones = {}
        for type in ['about', 'email', 'adr', 'tel', 'url', 'other']
            @zones[type] = @$('#' + type + 's ul')

        @hideEmptyZones()
        @spinner =    @$('#spinOverlay')
        @savedInfo = @$('#save-info').hide()
        @needSaving = false
        @namefield = @$('#name')
        @notesfield = @$('#notes')
        @uploader = @$('#uploader')[0]
        @picture  = @$('#picture .picture')
        @tags = new TagsView
            el: @$('#tags')
            model: @model
            contactView: @
        super
        @$el.niceScroll()
        @resizeNote()
        @currentState = @model.toJSON()

        @history = new HistoryView
            collection: @model.history
        @history.render().$el.appendTo @$('#history')

    remove: ->
        @$el.getNiceScroll().remove()
        super

    hideEmptyZones: ->
        for type, zone of @zones
            hasOne = @model.dataPoints.hasOne type
            zone.parent().toggle hasOne
            @$("#adder .add#{type}").toggle not hasOne

        for name in ['birthday', 'org', 'title', 'cozy']
            hasOne = @model.dataPoints.hasOne 'about', name
            @$("#adder .add#{name}").toggle not hasOne

        @$('#adder h2').toggle @$('#adder a:visible').length isnt 0
        @$el.getNiceScroll().resize()

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
        typeField = @zones[name].children().last().find('.type')
        typeField.focus()
        typeField.select()

    changeOccured: =>
        @model.set
            fn:  @namefield.val()
            note: @notesfield.val()
        return if _.isEqual @currentState, @model.toJSON()
        @needSaving = true
        @savedInfo.hide()
        @saveLater()

    delete: ->
        @model.destroy() if @model.isNew() or confirm t 'Are you sure ?'

    save: =>
        return unless @needSaving
        @needSaving = false
        @savedInfo.show().text 'saving changes'
        @model.save()

    undo: =>
        return unless @lastState
        @model.set @lastState, parse: true
        @model.save null, undo: true
        @resizeNote()

    onKeyUp: (event) ->
        # only enters
        return true unless (event.which or event.keyCode) is 13
        zone = $(event.target).parents('.zone')[0].id
        name = zone.substring 0, zone.length-1
        point = new Datapoint name: name
        @model.dataPoints.add point
        typeField = @zones[name].children().last().find('.type')
        typeField.focus()
        typeField.select()
        return false

    resizeNote: (event) ->
        notes = @notesfield.val()
        rows = loc = 0
        # count occurences of \n in notes
        while loc = notes.indexOf("\n", loc) + 1
            rows++

        @notesfield.prop 'rows', rows + 2
        @$el.getNiceScroll().resize()

    onRequest: ->
        @spinner.show()

    onSuccess: (model, result, options) ->
        @spinner.hide()
        if options.undo
            @savedInfo.text t('undone') + ' '
            @lastState = null
            setTimeout =>
                @savedInfo.fadeOut()
            , 1000
        else
            @savedInfo.text t('changes saved') + ' '
            undo = $("<a id='undo'>#{t('undo')}</a>")
            @savedInfo.append undo
            @lastState = @currentState

        @currentState = @model.toJSON()

    onError: ->
        @spinner.hide()

    modelChanged: =>
        @notesfield.val @model.get 'note'
        @namefield.val  @model.get 'fn'
        @tags?.refresh()
        @resizeNote()

    photoChanged: () =>

        file = @uploader.files[0]

        unless file.type.match /image\/.*/
            return alert t 'This is not an image'

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


