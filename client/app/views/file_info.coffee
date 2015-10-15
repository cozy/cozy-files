
###*
 * This module is in charge of displaying the file information in a popover when
 * the user let his mouse over the icon of the file.
 * For now we only display the thumbnail of file being an image.
###

module.exports = class FileInfo

    constructor: (elmt) ->

        @el  = elmt
        @img = document.createElement('img')
        @a   = document.createElement('a')
        @el.appendChild(@a).appendChild(@img)

        elmt.addEventListener 'mouseenter', (event) =>
            @stateMachine._enterPopo()

        elmt.addEventListener 'mouseleave', (event) =>
            @stateMachine._exitPopo()

        @a.addEventListener 'click', (event) =>
            # if ctrl => open link in new window : nothing to do
            if event.ctrlKey
                return
            # else show gallery
            window.app.gallery.show(@_currentTarget.model)
            event.preventDefault()

        # we use a finite state model to describe the states and
        # their transitions
        # 4 states :
        #   . Init          : the mouse is not over the link, the popover is hidden
        #   . WaitingToShow : the mouse is over the link, the popover is not yet visible
        #   . Visible       : the popopver is visible and the mouse is over the link or the popover
        #   . WaitingToHide : the popopver is visible and the mouse is neither over the link nor the popover

        events = [
            { from:'Init'          , to:'WaitingToShow' , name:'_enterLink'  }
            { from:'Init'          , to:'Init'          , name:'_exitLink'   }
            { from:'WaitingToShow' , to:'WaitingToShow' , name:'_enterLink'  }
            { from:'WaitingToShow' , to:'Visible'       , name:'_showTimer'  }
            { from:'WaitingToShow' , to:'Init'          , name:'_exitLink'   }
            { from:'Visible'       , to:'WaitingToHide' , name:'_exitLink'   }
            { from:'Visible'       , to:'WaitingToHide' , name:'_exitPopo'   }
            { from:'WaitingToHide' , to:'Visible'       , name:'_enterLink'  }
            { from:'WaitingToHide' , to:'Visible'       , name:'_enterPopo'  }
            { from:'WaitingToHide' , to:'Init'          , name:'_hideTimer'  }
        ]

        @stateMachine = StateMachine.create

            initial: 'Init'

            events : events

            # usefull for debug
            #  error: (eventName, from, to, args, errorCode, errorMessage) ->
            #     console.log '  event ' + eventName + ' was naughty :- ' + errorMessage

            callbacks:

                ####
                # A/ Callbacks on entering a state
                onenterWaitingToShow: (event,from,to) =>
                    # console.log '  onenterWaitingToShow',event, from, to
                    if from == 'Init'
                        @_startShowTimer()

                onenterVisible: (event,from,to) =>
                    # console.log '  onenterVisible', event, from, to
                    if from == 'WaitingToShow'
                        @_setNewTarget()
                        @_show()
                    else if from == 'WaitingToHide'
                        window.clearTimeout(@hideTimeout)
                        if @_lastEnteredTarget != @_currentTarget
                            @_setNewTarget()

                onenterWaitingToHide: (event,from,to) =>
                    # console.log '  onenterWaitingToHide', event, from, to
                    @_startHideTimer()

                onenterInit: (event,from,to) =>
                    # console.log '  onenterInit', event, from, to
                    if from == 'WaitingToHide'
                        @_hide()
                    else if from == 'WaitingToShow'
                        window.clearTimeout(@showTimeout)

                ####
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
        attr     = target.model.attributes
        @img.src = "files/photo/thumb/#{attr.id}"
        @a.href  = "files/#{attr.id}/attach/#{attr.name}"


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
