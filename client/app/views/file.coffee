TagsView    = require "../widgets/tags"
ProgressBar = require '../widgets/progressbar'

h   = virtualDom.h
svg = virtualDom.svg

mimeClasses =
    'application/octet-stream'      : 'fa-file-o'
    'application/x-binary'          : 'fa-file'
    'text/plain'                    : 'fa-file-text-o'
    'text/richtext'                 : 'fa-file-text-o'
    'application/x-rtf'             : 'fa-file-text-o'
    'application/rtf'               : 'fa-file-text-o'
    'application/msword'            : 'fa-file-word-o'
    'application/mspowerpoint'      : 'fa-file-powerpoint-o'
    'application/vnd.ms-powerpoint' : 'fa-file-powerpoint-o'
    'application/x-mspowerpoint'    : 'fa-file-powerpoint-o'
    'application/excel'             : 'fa-file-excel-o'
    'application/x-excel'           : 'fa-file-excel-o'
    'aaplication/vnd.ms-excel'      : 'fa-file-excel-o'
    'application/x-msexcel'         : 'fa-file-excel-o'
    'application/pdf'               : 'fa-file-pdf-o'
    'text/html'                     : 'fa-file-code-o'
    'text/asp'                      : 'fa-file-code-o'
    'text/css'                      : 'fa-file-code-o'
    'application/x-javascript'      : 'fa-file-code-o'
    'application/x-lisp'            : 'fa-file-code-o'
    'application/xml'               : 'fa-file-code-o'
    'text/xml'                      : 'fa-file-code-o'
    'application/x-sh'              : 'fa-file-code-o'
    'text/x-script.python'          : 'fa-file-code-o'
    'application/x-bytecode.python' : 'fa-file-code-o'
    'text/x-java-source'            : 'fa-file-code-o'
    'application/postscript'        : 'fa-image'
    'image/gif'                     : 'fa-image'
    'image/jpg'                     : 'fa-image'
    'image/jpeg'                    : 'fa-image'
    'image/pjpeg'                   : 'fa-image'
    'image/x-pict'                  : 'fa-image'
    'image/pict'                    : 'fa-image'
    'image/png'                     : 'fa-image'
    'image/x-pcx'                   : 'fa-image'
    'image/x-portable-pixmap'       : 'fa-image'
    'image/x-tiff'                  : 'fa-image'
    'image/tiff'                    : 'fa-image'
    'audio/aiff'                    : 'fa-file-audio-o'
    'audio/x-aiff'                  : 'fa-file-audio-o'
    'audio/midi'                    : 'fa-file-audio-o'
    'audio/x-midi'                  : 'fa-file-audio-o'
    'audio/x-mid'                   : 'fa-file-audio-o'
    'audio/mpeg'                    : 'fa-file-audio-o'
    'audio/x-mpeg'                  : 'fa-file-audio-o'
    'audio/mpeg3'                   : 'fa-file-audio-o'
    'audio/x-mpeg3'                 : 'fa-file-audio-o'
    'audio/wav'                     : 'fa-file-audio-o'
    'audio/x-wav'                   : 'fa-file-audio-o'
    'video/avi'                     : 'fa-file-video-o'
    'video/mpeg'                    : 'fa-file-video-o'
    'application/zip'               : 'fa-file-archive-o'
    'multipart/x-zip'               : 'fa-file-archive-o'
    'multipart/x-zip'               : 'fa-file-archive-o'
    'application/x-bzip'            : 'fa-file-archive-o'
    'application/x-bzip2'           : 'fa-file-archive-o'
    'application/x-gzip'            : 'fa-file-archive-o'
    'application/x-compress'        : 'fa-file-archive-o'
    'application/x-compressed'      : 'fa-file-archive-o'
    'application/x-zip-compressed'  : 'fa-file-archive-o'
    'multipart/x-gzip'              : 'fa-file-archive-o'


module.exports = class FileView

    className: 'folder-row'
    tagName:   'tr'


    constructor: (options) ->
        @model        = options.model
        @collection   = options.collection
        @isSearchMode = options.isSearchMode

        @isEditMode   = false
        @isBusy       = false
        @flashMessage = null
        @nodes        = {}

        @attrs =
            key:        @model.cid,
            className:  @className
            attributes:
                'data-vdom': @model.cid


    getDOMNode: (name) ->
        if name is 'el'
            @el
        else if @nodes[name]?
            @nodes[name]
        else
            @nodes[name] = @el.querySelector("[data-vdom=#{name}]")


    getVTree: (name) ->
        slug = "#{name}VTree"
        return @[slug] if @[slug]?
        return unless @elVTree
        do findVNode = (node = @elVTree) =>
            for child in node.children
                if child.properties?.attributes?['data-vdom'] is name
                    @[slug] = child
                    break
                else if child.children?
                    findVNode child
        return @[slug]


    patch: (component, vtree) ->
        if @getVTree(component)? and @el?
            patches = virtualDom.diff @getVTree(component), vtree
            node = virtualDom.patch @getDOMNode(component), patches
            @["#{component}VTree"] = vtree

        return node


    toggleEditMode: (toggle) ->
        toggle ?= !@isEditMode
        @isEditMode = toggle
        if @model.isNew() then @model.destroy()
        @render()


    saveEdit: ->
        name = @el.querySelector('.file-edit-name').value

        if name
            @isBusy = true
            @renderIcons()

            @model.save name: name,
                wait: true,
                success: (data) =>
                    @isEditMode = false
                    @isBusy     = false
                    @render()
                error: (model, err) =>
                    @isEditMode   = true
                    @isBusy       = false
                    @flashMessage = if err.status is 400
                        t 'modal error in use'
                    else
                        t 'modal error rename'
                    @render()

        else
            @flashMessage = t 'modal error empty name'
            @render()


    displayError: (msg) ->
        @errorField ?= $('<span class="error">').insertAfter @$('.file-edit-cancel')
        if msg is false then @errorField.hide()
        else @errorField.text msg


    renderPath: ->
        unless @isSearchMode then return null

        vtree = h 'p.file-path',
            textContent: "#{@model.get 'path'}/"
            attributes: 'data-vdom': 'path'

        @patch 'path', vtree
        return vtree


    renderIcons: ->
        vtree = h 'span.icon-zone', attributes: 'data-vdom': 'icons'

        spinholderClassname  = ".spinholder"
        spinholderClassname += ".hidden" unless @isBusy
        vtree.children.push h spinholderClassname, [
                h 'img', {src: 'images/spinner.svg'}]

        vtree.children.push h 'div.selector-wrapper', [
            h 'input.selector', {type: 'checkbox'}]

        mime = @model.get 'mime'
        if @model.get('type') is 'folder'
            typeClass = 'fa-folder'
        else if mime and mimeClasses[mime]
            typeClass = mimeClasses[mime]
        else
            typeClass = 'fa-file-o'

        clearance = @model.getClearance()
        if clearance is 'public' or clearance?.length
            vtree.children.push h 'span.fa.fa-globe'
            typeClass += '-o' if @model.get('type') is 'folder'

        iconClassname  = ".fa.#{typeClass}"
        iconClassname += ".hidden" if @isBusy
        vtree.children.push h "i#{iconClassname}"

        @patch 'icons', vtree
        return vtree


    renderName: ->
        attrs = attributes: 'data-vdom': 'name'

        if @isEditMode
            ctrl = 'a.btn.btn-sm'
            vtree = h 'span', attrs, [
                h 'input.caption.file-edit-name', value: @model.get 'name'
                h "#{ctrl}.btn-cozy.file-edit-save", t 'file edit save'
                h "#{ctrl}.btn-link.file-edit-cancel", t 'file edit cancel']

            vtree.children.push h 'span.error', @flashMessage if @flashMessage?
            @flashMessage = null

        else
            if @model.get('type') is 'folder'
                _.extend attrs,
                    href: "#folders/#{@model.get 'id'}"
                    title: t 'open folder'
            else
                _.extend attrs,
                    href: @model.getAttachmentUrl()
                    title: t 'download file'
                    target: '_blank'

            vtree = h 'a.btn-link', attrs, [
                h 'span', @model.get 'name']

        @patch 'name', vtree
        return vtree


    renderTags: ->
        vtree = h 'ul.tags', attributes: 'data-vdom': 'tags'
        _.each @model.get('tags'), (tag) ->
            vtree.children.push h 'li.tag', textContent: tag, [
                h 'span.deleter', innerHTML: ' &times; ']

        @patch 'tags', vtree
        return vtree


    renderSize: ->
        if @model.get('type') is 'file'
            file = filesize(@model.get('size') || 0, {base: 2})
        vtree = h 'span', attributes: 'data-vdom': 'size', file

        @patch 'size', vtree
        return vtree


    renderLastModification: ->
        if @model.get 'lastModification'
            dateTime = moment(@model.get 'lastModification').calendar()

        vtree = h 'span', attributes: 'data-vdom': 'date', dateTime

        @patch 'date', vtree
        return vtree


    buildVTree: (fill = true) ->
        return [] unless fill

        editMode = if @isEditMode then '.caption-edit' else ''
        name = h 'td', [
            @renderPath()
            h ".caption.btn.btn-link#{editMode}", [
                @renderIcons(), @renderName()]
            @renderTags()]

        operations = h 'td.operations-column-cell'
        unless @isEditMode
            operations.children = [
                h 'a.file-tags', {title: t 'tooltip tag'}, [
                    svg 'svg', {innerHTML: '<use xlink:href="#icon-tag"/>'}]
                h 'a.file-share', {title: t 'tooltip share'}, [
                    svg 'svg', {innerHTML: '<use xlink:href="#icon-share"/>'}]
                h 'a.file-edit', {title: t 'tooltip edit'}, [
                    svg 'svg', {innerHTML: '<use xlink:href="#icon-edit"/>'}]
                h 'a.file-download', {title: t 'tooltip download'}, [
                    svg 'svg', {innerHTML: '<use xlink:href="#icon-download"/>'}
            ]]

        size = h 'td.size-column-cell', [@renderSize()]

        typeText = if @model.get('type') is 'folder'
            'folder'
        else
            @model.get 'class'
        type = h 'td.type-column-cell', [
            h 'span.pull-left', t typeText]

        date = h 'td.date-column-cell', [@renderLastModification()]

        [name, operations, size, type, date]


    render: (fill = true) ->
        unless @elVTree?
            @elVTree = h @tagName, @attrs, @buildVTree(fill)

        collectionNode = @collection.collectionNode
        if collectionNode.children.length and not @el?
            @el = collectionNode.querySelector "[data-vdom=#{@model.cid}]"

        return @ unless @el?

        if @model.hasChanged()
            _.each @model.changed, (value, name) =>
                action = "render#{name[0].toUpperCase()}#{name[1..-1]}"
                @[action]() if @[action]?
        else
            @el = @patch 'el', h(@tagName, @attrs, @buildVTree(fill))

        @afterRender()


    afterRender: ->
        $el = @collection.$el.find "[data-vdom=#{@model.cid}]"
        @el ?= $el[0]

        $el
        .find '.fa-folder'
            .toggleClass 'spin', @hasUploadingChildren?

        @el.classList.toggle('edit-mode', @isEditMode)

        @_renderEditMode() if @isEditMode
        @_renderUploadMode($el) if @model.isBeingUploaded()
        @_renderTags($el.find '.tags') unless @model.isBeingUploaded()

        return @


    _renderUploadMode: ($el)->
        # TODO: revamp this progressbar injectiom runtime
        # if the file is being uploaded
        $el.find('.type-column-cell').remove()
        $el.find('.date-column-cell').remove()

        @progressbar = new ProgressBar model: @model
        cell = $ '<td colspan="2"></td>'
        cell.append @progressbar.render().$el
        @$('.size-column-cell').after cell

        # we don't want the file link to react
        @$('a.caption.btn').click (event) -> event.preventDefault()


    _renderTags: ($tags) ->
        return unless $tags.is(':empty')
        # TODO: let tags auto bind themselves outside of the view logic
        @tags = new TagsView
            el: $tags
            model: @model
        @tags.render()
        @tags.hideInput()


    _renderEditMode: ->
        name = @model.get('name')
        # we only want to select the part before the file extension
        lastIndexOfDot = name.lastIndexOf '.'
        lastIndexOfDot = name.length if lastIndexOfDot is -1
        input = @el.querySelector('.file-edit-name')

        if typeof input.selectionStart isnt "undefined"
            input.selectionStart = 0
            input.selectionEnd = lastIndexOfDot
        else if document.selection && document.selection.createRange
            # IE Branch...
            input.select()
            range = document.selection.createRange()
            range.collapse true
            range.moveStart "character", 0
            range.moveEnd "character", lastIndexOfDot
            range.select()

        input.focus()
