BaseView = require 'lib/base_view'
Contact  = require 'models/contact'
app      = require 'application'

module.exports = class ImporterView extends BaseView

    template: require 'templates/importer'

    id: 'importer'
    tagName: 'div'
    className: 'modal'

    events: ->
        'change #vcfupload': 'onupload'
        'click  #confirm-btn': 'addcontacts'

    afterRender: ->
        @$el.modal()
        @upload = @$('#vcfupload')[0]
        @content = @$('.modal-body')
        @confirmBtn = @$('#confirm-btn')

    onupload: ->
        file = @upload.files[0]
        validMimeTypes = ['text/vcard', 'text/x-vcard', 'text/directory',
                          'text/directory;profile=vcard']
        if file.type.toLowerCase() not in validMimeTypes
            @$('.control-group').addClass 'error'
            @$('.help-inline').text t 'is not a vCard'
            return

        reader = new FileReader()
        reader.readAsText file
        reader.onloadend = =>
            @toImport = Contact.fromVCF reader.result

            txt = t 'import.ready-msg', smart_count: @toImport
            txt = "<p>#{txt} :</p><ul>"
            @toImport.each (contact) ->
                txt += "<li>#{contact.get 'fn'}</li>"
            txt += '</ul>'
            @content. html txt
            @confirmBtn.removeClass 'disabled'

    addcontacts: ->
        return true unless @toImport

        @toImport.each (contact) ->
            contact.save null,
                success: ->
                    app.contacts.add contact

        @close()

    close: ->
        @$el.modal 'hide'
        @remove()