
###*
 * This module is in charge of displaying the file information in a popover when
 * the user lets his mouse over the icon of the file.
 * For now we only display the thumbnail of files being an image.
###

ARROW_TOP_OFFSET       = 17  # top offset in pixels for the arrow of the popover
POPOVER_DEFAULT_HEIGHT = 310 # height of thumbnails

module.exports = class FileInfo

    constructor: (elmt) ->

        # A] DOM of the Popover
        @el    = elmt
        @img   = document.createElement('img')
        @a     = document.createElement('a')
        @arrow = document.createElement('div')
        @el.appendChild(@a).appendChild(@img)
        @el.appendChild(@arrow)

        # B] EVENTS LISTENERS ON POPOVER
        elmt.addEventListener 'mouseenter', (event) =>
            @_isIntoPopover = true
            @stateMachine.E3_enterPopo()
        elmt.addEventListener 'mouseleave', (event) =>
            @_isIntoPopover = false
            @stateMachine.E4_exitPopo()
        @a.addEventListener 'click', (event) =>
            unless event.ctrlKey
                # Show the gallery
                window.app.gallery.show(@_currentTarget.model)
                event.preventDefault()

        # C] EVENTS LISTENERS ON IMG
        @_previousPopoverHeight = POPOVER_DEFAULT_HEIGHT
        @img.onload = (event) =>
            dim = @el.getBoundingClientRect()
            if @_previousPopoverHeight != dim.height
                @_previousPopoverHeight = dim.height

        # D] TRACK MOUSE POSITION to check it is in the column of the files icons,
        # or it goes out of the column (+-10px)
        @_columnGardian.init(@)

        # E] FINITE STATE MACHINE CONFIGURATION
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
        #   . E3_enterPopo  : Enter popover
        #   . E4_exitPopo   : Exit popover
        #   . E5_showTimer  :
        #   . E6_hideTimer  :
        #   . E7_enterCol   : the mouse enters the column of the thumbnail
        #   . E8_exitCol    : the mouse exits  the column of the thumbnail
        #   . E9_linkNoData :

        @stateMachine = StateMachine.create

            initial: 'S1_Init'

            events : [

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

            # usefull for debug
            # error: (eventName, from, to, args, errorCode, errorMessage) ->
            #     console.log '  event ' , eventName + ' from:', from,' to', to, ' was naughty : ' , errorMessage

            callbacks:

                ####
                # A/ Callbacks on entering or leaving a state
                onenterS2_WaitingToShow: (event,from,to) =>
                    if from is 'S1_Init'
                        @_startShowTimer()
                        @_lastEnteredTarget.el.querySelector('.icon-type').style.cursor = 'wait'
                        @_columnGardian.start()

                onleaveS2_WaitingToShow: (event,from,to) =>
                    @_lastEnteredTarget.el.querySelector('.icon-type').style.cursor = ''

                onenterS3_Visible: (event,from,to) =>
                    if from is 'S2_WaitingToShow'
                        @_setNewTarget()
                        @_show()
                    else if from is 'S4_WaitingToHide'
                        window.clearTimeout(@hideTimeout)
                        if @_lastEnteredTarget != @_currentTarget
                            @_setNewTarget()

                onenterS4_WaitingToHide: (event,from,to) =>
                    @_startHideTimer()

                onenterS1_Init: (event,from,to) =>
                    if from is 'S4_WaitingToHide'
                        @_hide()
                        @_columnGardian.stop()
                    else if from is 'S2_WaitingToShow'
                        window.clearTimeout(@showTimeout)
                        @_columnGardian.stop()

                ####
                # B/ Callbacks on entering an event to cancel it if required
                onbeforeE1_enterLink: (event,from, to) =>
                    if @_hasInfoToDisplay(@_lastEnteredTarget)
                        if from is to and to is 'S3_Visible'
                            @_setNewTarget()
                        return true
                    else
                        if from is 'S3_Visible'
                            @stateMachine.E9_linkNoData()
                        return false

                onbeforeE2_exitLink: (event,from, to) =>
                    if !@_hasInfoToDisplay(@_lastEnteredTarget)
                        return false

                onbeforeE8_exitCol: (event,from, to) =>
                    # exit col can occur after enterPopover because the widht of
                    # the column is over the popover... So exit the column is
                    # after the entre popover event.
                    return !@_isIntoPopover

    ###*
     * Moves the popover on its corresponding thumbnail target.
    ###
    _setNewTarget:() ->
        # update position (takes care if the thumbnail is too low in the window)
        target          = @_lastEnteredTarget
        @_currentTarget = target
        el              = target.el
        topFileInfo     = el.offsetTop
        scrollTop       = el.offsetParent.scrollTop
        clientHeight    = el.offsetParent.clientHeight
        popoverTop      = topFileInfo - scrollTop
        popoverBottom   = popoverTop + @_previousPopoverHeight
        if popoverBottom < clientHeight
            @el.style.top   = popoverTop + 'px'
            @arrow.style.top = ARROW_TOP_OFFSET + 'px'
        else
            @el.style.top   = (clientHeight - @_previousPopoverHeight) + 'px'
            arrowTop = popoverTop - clientHeight + @_previousPopoverHeight + ARROW_TOP_OFFSET
            arrowTop = Math.min(arrowTop, @_previousPopoverHeight - 12 )
            @arrow.style.top = arrowTop + 'px'
        # update content
        @img.src = target.model.getThumbUrl()
        @a.href  = target.model.getAttachmentUrl()


    _show: () ->
        @el.style.display = 'block'
        @el.classList.add('ease')


    _hide: () ->
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
        return targetView.model.attributes.binary?.thumb?


    onEnterLink: (targetView)->
        @_lastEnteredTarget =
            el    : targetView.el
            model : targetView.model
        @stateMachine.E1_enterLink()


    onExitLink: (targetView)->
        if @stateMachine.current is 'S2_WaitingToShow'
            @stateMachine.E2_exitLink()



    _columnGardian :

        init: (file_info_ctlr)->

            @file_info_ctlr = file_info_ctlr
            @FIC_container = file_info_ctlr.el.parentElement
            @_computeColumnWidth()

            # update the col positions when the window is resized
            computeColAfterResize = _.debounce () =>
                @_computeColumnWidth()
            , 1000
            window.addEventListener("resize", computeColAfterResize, false)

            # callback to track if the mouse remains or not in the column of the
            # thumbnails.
            @mouseMoved = (ev) =>
                isInCol = this.col_left < ev.pageX
                isInCol = isInCol &&  ev.pageX < this.col_right
                if this.isInCol != isInCol
                    if isInCol
                        this.file_info_ctlr.stateMachine.E7_enterCol()
                    else
                        this.file_info_ctlr.stateMachine.E8_exitCol()
                    this.isInCol = isInCol

        _computeColumnWidth: ()->
            thumb = @FIC_container.querySelector('.icon-type')
            return if thumb is null
            dimensions = thumb.getBoundingClientRect()
            this.col_left  = dimensions.left - 10
            this.col_right = this.col_left + dimensions.width + 20
            captionWrapper = @FIC_container.querySelector('.caption-wrapper')
            @file_info_ctlr.el.style.left   = (captionWrapper.offsetLeft + 42) + 'px'

        start: ()->
            @FIC_container.addEventListener("mousemove", @mouseMoved, false)
            @isInCol = true

        stop : ()->
            @FIC_container.removeEventListener("mousemove", @mouseMoved, false)




