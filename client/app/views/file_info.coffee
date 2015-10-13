

module.exports = class FileInfo

    constructor: (elmt) ->

        @el  = elmt
        @_thumbEl = document.createElement('img')
        @el.appendChild(@_thumbEl)

        elmt.addEventListener 'mouseenter', (event) =>
            @stateMachine._enterPopo()

        elmt.addEventListener 'mouseleave', (event) =>
            @stateMachine._exitPopo()

        events = []
        events.push name:'_enterLink' , from:'Init'       , to:'WaitToShow'
        events.push name:'_enterLink' , from:'WaitToShow' , to:'WaitToShow'
        events.push name:'_enterLink' , from:'WaitToHide' , to:'Visible'
        events.push name:'_showTimer' , from:'WaitToShow' , to:'Visible'
        events.push name:'_exitLink'  , from:'Visible'    , to:'WaitToHide'
        events.push name:'_exitLink'  , from:'Init'       , to:'Init'
        events.push name:'_exitLink'  , from:'WaitToShow' , to:'Init'
        events.push name:'_enterPopo' , from:'WaitToHide' , to:'Visible'
        events.push name:'_exitPopo'  , from:'Visible'    , to:'WaitToHide'
        events.push name:'_hideTimer' , from:'WaitToHide' , to:'Init'

        @stateMachine = StateMachine.create

            initial: 'Init'

            events : events

            # error: (eventName, from, to, args, errorCode, errorMessage) ->
            #     console.log '  event ' + eventName + ' was naughty :- ' + errorMessage

            callbacks:

                # A/ Callbacks on entering a state
                onenterWaitToShow: (event,from,to) =>
                    # console.log '  onenterWaitToShow',event, from, to
                    if from == 'Init'
                        @_startShowTimer()

                onenterVisible: (event,from,to) =>
                    # console.log '  onenterVisible', event, from, to
                    if from == 'WaitToShow'
                        @_setNewTarget()
                        @_show()
                    else if from == 'WaitToHide'
                        window.clearTimeout(@hideTimeout)
                        if @_lastEnteredTarget != @_currentTarget
                            @_setNewTarget()

                onenterWaitToHide: (event,from,to) =>
                    # console.log '  onenterWaitToHide', event, from, to
                    @_startHideTimer()

                onenterInit: (event,from,to) =>
                    # console.log '  onenterInit', event, from, to
                    if from == 'WaitToHide'
                        @_hide()
                    else if from == 'WaitToShow'
                        window.clearTimeout(@showTimeout)

                # B/ Callbacks on entering an event to cancel it if required
                onbefore_enterLink: (event,from, to) =>
                    # console.log '  onbefore_enterLink', @_hasInfoToDisplay(@_lastEnteredTarget)
                    if !@_hasInfoToDisplay(@_lastEnteredTarget)
                        return false
                    else
                        return true

                onbefore_exitLink: (event,from, to) =>
                    # console.log '  onbefore_exitLink', @_hasInfoToDisplay(@_lastEnteredTarget)
                    if !@_hasInfoToDisplay(@_lastEnteredTarget)
                        return false


    _setNewTarget:() ->
        # console.log '_setNewTarget'
        # update position
        target          = @_lastEnteredTarget
        @_currentTarget = target
        topFileInfo     = target.el.offsetTop
        scrollTop       = target.el.offsetParent.scrollTop
        @el.style.top   = (topFileInfo - scrollTop) + 'px'
        # update content
        @_thumbEl.src = "files/photo/thumb/#{target.model.attributes.id}"


    _show: () ->
        # console.log '_show'
        @el.style.display = 'block'
        @el.classList.add('ease')


    _hide: () ->
        # console.log '_hide'
        @el.style.display = 'none'
        @el.classList.remove('ease')


    _startShowTimer: ()->
        @showTimeout = window.setTimeout () =>
            @stateMachine._showTimer()
        , 700


    _startHideTimer: ()->
        @hideTimeout = window.setTimeout () =>
            @stateMachine._hideTimer()
        , 300

    ###*
     * Return false if the model corresponds to a file which has no info to
     * display in the popover. For now only files with thumbnails are concerned.
     * @param  {View}  targetView Backbone view of the file
     * @return {Boolean}  True if the file has info to display in the
     *                    popover, false otherwise.
    ###
    _hasInfoToDisplay: (targetView)->
        if targetView.model.attributes.binary?.thumb?
            return true
        else
            return false


    onEnterLink: (targetView)->
        # console.log 'onEnterLink', @stateMachine.current
        @_lastEnteredTarget =
            el    : targetView.el
            model : targetView.model
        @stateMachine._enterLink()


    onExitLink: (targetView)->
        # console.log 'onExitLink', @stateMachine.current
        @stateMachine._exitLink()
