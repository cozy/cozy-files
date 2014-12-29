helpers =
    # Available options:
    # title: modal window title
    # body: modal window body
    # size: null, 'small' or 'large'
    # show: if not false, show modal
    modal: (options) ->
        win = document.createElement 'div'
        win.classList.add 'modal'
        win.classList.add 'fade'
        win.innerHTML = '<div class="modal-dialog"> <div class="modal-content"> <div class="modal-header"> <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button> <h4 class="modal-title"></h4> </div> <div class="modal-body"> </div> <div class="modal-footer"> <button type="button" class="btn btn-default" data-dismiss="modal">Close</button> </div> </div> </div>'
        if options.title
            win.querySelector('.modal-title').innerHTML = options.title
        if options.body
            win.querySelector('.modal-body').innerHTML = options.body
        if options.size is 'small'
            win.querySelector('.modal-dialog').classList.add 'modal-sm'
        if options.size is 'large'
            win.querySelector('.modal-dialog').classList.add 'modal-lg'
        if options.show isnt false
            document.body.appendChild win
            window.jQuery(win).modal 'show'
        return win

module.exports =

    init: ->
        if not window.plugins?
            window.plugins = {}

        window.plugins.helpers = helpers

        for own pluginName, pluginConf of window.plugins
            @activate pluginName

        if MutationObserver?

            config =
                attributes: false
                childList: true
                characterData: false
                subtree: true

            onMutation = (mutations) ->
                checkNode = (node, action) ->
                    if node.nodeType isnt Node.ELEMENT_NODE
                        return

                    for own pluginName, pluginConf of window.plugins
                        if pluginConf.active
                            listener = pluginConf.onAdd if action is 'add'
                            listener = pluginConf.onDelete if action is 'delete'
                            if listener? and
                            listener.condition.bind(pluginConf)(node)
                                listener.action.bind(pluginConf)(node)

                check = (mutation) ->

                    nodes = Array.prototype.slice.call mutation.addedNodes
                    checkNode node, 'add' for node in nodes

                    nodes = Array.prototype.slice.call mutation.removedNodes
                    checkNode node, 'del' for node in nodes

                check mutation for mutation in mutations

            # Observes DOM mutation to see if a plugin should be called
            observer = new MutationObserver onMutation
            observer.observe document, config

        else
            # Dirty fallback for IE
            # @TODO use polyfill ???
            setInterval ->
                for own pluginName, pluginConf of window.plugins
                    if pluginConf.active
                        if pluginConf.onAdd?
                            if pluginConf.onAdd.condition document.body
                                pluginConf.onAdd.action document.body

            , 200

    activate: (key) ->
        plugin = window.plugins[key]
        type   = plugin.type
        plugin.active = true

        # Add custom events listeners
        if plugin.listeners?
            for own event, listener of plugin.listeners
                window.addEventListener event, listener.bind(plugin)

        if plugin.onActivate
            plugin.onActivate()

        if type?
            for own pluginName, pluginConf of window.plugins
                if pluginName is key
                    continue
                if pluginConf.type is type and pluginConf.active
                    @deactivate pluginName

    deactivate: (key) ->
        plugin = window.plugins[key]
        plugin.active = false

        # remove custom events listeners
        if plugin.listeners?
            for own event, listener of plugin.listeners
                window.removeEventListener event, listener

        if plugin.onDeactivate
            plugin.onDeactivate()


