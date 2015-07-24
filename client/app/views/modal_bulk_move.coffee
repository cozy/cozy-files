Modal = require "./modal"
client = require "../lib/client"

module.exports = class ModalBulkMoveView extends Modal

    formTemplate: -> """
            <div class="move-widget">
            <span> #{t 'move elements to'}: </span>
            <select class="move-select"></select>
            </div>
    """

    movedTemplate: (path) ->
        """
        <div id="moved-infos">
        <span>#{ t 'elements successfully moved to'}: /#{path}.</span>
        <button class="btn btn-link cancel-move-btn">
            #{t 'cancel'}
        </button>
        </div>
    """

    optionTemplate: (path) -> """
        <option value="#{path}">#{path}</option>
    """

    constructor: (options) ->

        super t('moving selected elements'), '', t('move'), t('close')

        # collection is the selected elements
        @collection = options.collection
        @parentPath = options.parentPath

    afterRender: ->
        # retrieve list of all folders
        client.get 'folders/list', (err, paths) =>
            if err?
                Modal.error err
            else
                # Add root folder to list.
                paths.push '/' if @parentPath isnt  ""

                # generate the list of paths where elements cannot be moved
                # this list is composed of the selected folders
                forbiddenPaths = @collection
                    .filter (element) -> element.isFolder()
                    .map (element) -> element.getRepository()

                allowedPaths = _.filter paths, (path) =>
                    # we append a / to prevent issue where folders
                    # share the same prefix
                    testedPath = path + '/'

                    # if the path is a child of one of the forbidden paths
                    # or the parent path, then it should not be displayed
                    isAllowed = not _.some forbiddenPaths, (forbiddenPath) ->
                        testedPath.indexOf(forbiddenPath) is 0

                    return isAllowed and path isnt @parentPath

                # Fill folder combobox with folder list.
                @moveForm = $ @formTemplate()
                for path in allowedPaths
                    @moveForm.find('select').append @optionTemplate path

                @$el.find('.modal-body').append @moveForm

    onYes: ->
        # Shows loading indicator
        @$('#modal-dialog-yes').html t 'moving...'

        # Gets the new path
        newPath = $('.move-select').val().substring 1
        previousPath = @parentPath

        @bulkUpdate newPath, (err) =>
            # Hides loading indicator
            @$('#modal-dialog-yes').hide()

            if err?
                # Shows an error
                Modal.error t 'modal error file exists'
            else
                # Shows the success form
                @moveForm.fadeOut => @moveForm.remove()
                movedInfos = $ @movedTemplate newPath

                # Cancel handler
                cancelButton =  movedInfos.find '.cancel-move-btn'
                cancelButton.click =>
                    @bulkUpdate previousPath, (err) =>
                        if err?
                            Modal.error t 'error occured canceling move'
                        else
                            @onNo()

                @$el.find('.modal-body').append movedInfos

    # Process the update for all the selected elements
    bulkUpdate: (newPath, callback) ->
        window.pendingOperations.move++
        # Process the update 1 by 1
        async.eachSeries @collection, (model, cb) ->
            id = model.get 'id'
            type = model.get 'type'
            client.put "#{type}s/#{id}", path: newPath, cb
        , ->
            window.pendingOperations.move--
            callback()
