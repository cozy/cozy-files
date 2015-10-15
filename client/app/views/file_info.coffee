
###*
 * This module is in charge of displaying the file information in a popover when
 * the user let his mouse over the icon of the file.
 * For now we only display the thumbnail of file being an image.
###

module.exports = class FileInfo

    constructor: (elmt) ->

        # DOM
        @el  = elmt
        @img = document.createElement('img')
        @a   = document.createElement('a')
        @el.appendChild(@a).appendChild(@img)

        # EVENTS LISTENERS
        elmt.addEventListener 'mouseenter', (event) =>
            @_isIntoPopover = true
            @stateMachine.E3_enterPopo()
        elmt.addEventListener 'mouseleave', (event) =>
            @_isIntoPopover = false
            @stateMachine.E4_exitPopo()
        @a.addEventListener 'click', (event) =>
            # if ctrl => open link in new window : nothing to do
            if event.ctrlKey
                return
            # else show gallery
            window.app.gallery.show(@_currentTarget.model)
            event.preventDefault()

        # TRACK MOUSE POSITION to check it is in the column of the files icons,
        # or it goes out of the column (+-10px)
        @_columnGardian.init(@)


        # FINITE STATE MACHINE CONFIGURATION
        # we use a finite state model to describe the states and
        # their transitions
        # States :
        #   . S1_Init          : the mouse is not over the link, the popover is hidden
        #   . S2_WaitingToShow : the mouse is over the link, the popover is not yet visible
        #   . S3_Visible       : the popopver is visible and the mouse is over the link or the popover
        #   . S4_WaitingToHide : the popopver is visible and the mouse is neither over the link nor the popover
        #  Events :
        #   . E1_enterLink  :
        #   . E2_exitLink   :
        #   . E3_enterPopo  :
        #   . E4_exitPopo   :
        #   . E5_showTimer  :
        #   . E6_hideTimer  :
        #   . E7_enterCol   :
        #   . E8_exitCol    :
        #   . E9_linkNoData :

        events = [

            { from:'S1_Init'          , to:'S2_WaitingToShow' , name:'E1_enterLink'  }
            { from:'S1_Init'          , to:'S1_Init'          , name:'E4_exitPopo'   } # can occur... why ?

            { from:'S2_WaitingToShow' , to:'S3_Visible'       , name:'E5_showTimer'  }
            { from:'S2_WaitingToShow' , to:'S1_Init'          , name:'E8_exitCol'    }
            { from:'S2_WaitingToShow' , to:'S1_Init'          , name:'E2_exitLink'   }
            { from:'S2_WaitingToShow' , to:'S2_WaitingToShow' , name:'E1_enterLink'  }

            { from:'S3_Visible'       , to:'S4_WaitingToHide' , name:'E4_exitPopo'   }
            { from:'S3_Visible'       , to:'S4_WaitingToHide' , name:'E8_exitCol'    }
            { from:'S3_Visible'       , to:'S4_WaitingToHide' , name:'E9_linkNoData' }
            { from:'S3_Visible'       , to:'S3_Visible'       , name:'E1_enterLink'  }
            { from:'S3_Visible'       , to:'S3_Visible'       , name:'E3_enterPopo'  }
            { from:'S3_Visible'       , to:'S3_Visible'       , name:'E7_enterCol'   }

            { from:'S4_WaitingToHide' , to:'S3_Visible'       , name:'E1_enterLink'  }
            { from:'S4_WaitingToHide' , to:'S3_Visible'       , name:'E3_enterPopo'  }
            { from:'S4_WaitingToHide' , to:'S3_Visible'       , name:'E7_enterCol'   }
            { from:'S4_WaitingToHide' , to:'S1_Init'          , name:'E6_hideTimer'  }
            { from:'S4_WaitingToHide' , to:'S4_WaitingToHide' , name:'E4_exitPopo'   } # can occur... why ?
        ]

        @stateMachine = StateMachine.create

            initial: 'S1_Init'

            events : events

            # usefull for debug
            # error: (eventName, from, to, args, errorCode, errorMessage) ->
            #     console.log '  event ' , eventName + ' from:', from,' to', to, ' was naughty : ' , errorMessage

            callbacks:

                ####
                # A/ Callbacks on entering a state
                onenterS2_WaitingToShow: (event,from,to) =>
                    # console.log '  onenterS2_WaitingToShow',event, from, to
                    if from == 'S1_Init'
                        @_startShowTimer()
                        @_columnGardian.start()

                onenterS3_Visible: (event,from,to) =>
                    # console.log '  onenterS3_Visible', event, from, to
                    if from == 'S2_WaitingToShow'
                        @_setNewTarget()
                        @_show()
                    else if from == 'S4_WaitingToHide'
                        window.clearTimeout(@hideTimeout)
                        if @_lastEnteredTarget != @_currentTarget
                            @_setNewTarget()

                onenterS4_WaitingToHide: (event,from,to) =>
                    # console.log '  onenterS4_WaitingToHide', event, from, to
                    @_startHideTimer()

                onenterS1_Init: (event,from,to) =>
                    # console.log '  onenterInit', event, from, to
                    if from == 'S4_WaitingToHide'
                        @_hide()
                        @_columnGardian.stop()
                    else if from == 'S2_WaitingToShow'
                        window.clearTimeout(@showTimeout)
                        @_columnGardian.stop()

                ####
                # B/ Callbacks on entering an event to cancel it if required
                onbeforeE1_enterLink: (event,from, to) =>
                    # console.log '  onbeforeE1_enterLink', @_hasInfoToDisplay(@_lastEnteredTarget), from, to
                    if @_hasInfoToDisplay(@_lastEnteredTarget)
                        if from == to == 'S3_Visible'
                            @_setNewTarget()
                        return true
                    else
                        if from == 'S3_Visible'
                            @stateMachine.E9_linkNoData()
                        return false

                onbeforeE2_exitLink: (event,from, to) =>
                    # console.log '  onbeforeE2_exitLink', @_hasInfoToDisplay(@_lastEnteredTarget), from, to
                    if !@_hasInfoToDisplay(@_lastEnteredTarget)
                        return false

                onbeforeE8_exitCol: (event,from, to) =>
                    # exit col can occur after enterPopover because the widht of
                    # the column is over the popover... So exit the column is
                    # after the entre popover event.
                    if @_isIntoPopover
                        return false
                    else
                        return true


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
            @stateMachine.E5_showTimer()
        , 700


    _startHideTimer: ()->
        @hideTimeout = window.setTimeout () =>
            @stateMachine.E6_hideTimer()
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
        @stateMachine.E1_enterLink()


    onExitLink: (targetView)->
        # console.log 'onExitLink', @stateMachine.current
        if @stateMachine.current == 'S2_WaitingToShow'
            @stateMachine.E2_exitLink()



    _columnGardian :

        init: (file_info_ctlr)->
            @file_info_ctlr = file_info_ctlr
            @FIC_container = file_info_ctlr.el.parentElement
            thumb = @FIC_container.querySelector('img.type-thumb')
            dimensions = thumb.getBoundingClientRect()
            this.col_left  = dimensions.left - 10
            this.col_right = this.col_left + dimensions.width + 20
            this.isInCol = false
            @mouseMoved = (ev) =>
                # console.log '_mouseMoved', ev.pageX, ev.pageY
                isInCol = this.col_left < ev.pageX
                isInCol = isInCol &&  ev.pageX < this.col_right
                if this.isInCol != isInCol
                    if isInCol
                        this.file_info_ctlr.stateMachine.E7_enterCol()
                    else
                        this.file_info_ctlr.stateMachine.E8_exitCol()
                    this.isInCol = isInCol

        start: ()->
            @FIC_container.addEventListener("mousemove", @mouseMoved, false)
            @isInCol = true

        stop : ()->
            @FIC_container.removeEventListener("mousemove", @mouseMoved, false)




