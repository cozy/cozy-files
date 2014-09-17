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
        $(".loading").show()

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
                name = contact.get('fn') or contact.getComputedFN()
                if not name? or name.trim() is ''
                    name = contact.getBest 'email'
                if not name? or name.trim() is ''
                    name = contact.getBest 'tel'
                txt += "<li>#{name}</li>"
            txt += '</ul>'
            @content. html txt
            @confirmBtn.removeClass 'disabled'

    updateProgress: (number, total) ->
        @$(".import-progress").html " #{number} / #{total}"

    addcontacts: ->
        return true unless @toImport
        @content.html """
        <p>#{t('dont close navigator import')}</p>
        <p>
            #{t('import progress')}:&nbsp;<span class="import-progress"></span>
        </p>
        <p class="errors">
        </p>
        """
        total = @toImport.length
        @importing = true
        @updateProgress 0, total

        (importContact = =>
            if @toImport.length is 0
                alert t 'import succeeded'
                @importing = false
                @close()
            else
                contact = @toImport.pop()

                contact.set 'import', true
                contact.save null,
                    success: =>
                        @updateProgress (total - @toImport.size()), total
                        app.contacts.add contact
                        importContact()
                    error: =>
                        $(".errors").append """
                        <p>#{t 'fail to import'}: #{contact.getComputedFN()}</p>
                        """
                        importContact()
        )()

    close: ->
        unless @importing
            @$el.modal 'hide'
            @remove()
