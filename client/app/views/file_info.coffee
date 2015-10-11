

module.exports = class FileInfo

    constructor: (elmt) ->
        @el = elmt
        elmt.addEventListener 'mouseenter', (event) =>
            @stateMachine.enterPopo()
        elmt.addEventListener 'mouseleave', (event) =>
            @stateMachine.exitPopo()

        events = []
        events.push name:'enterLink' , from:'init'       , to:'waitToShow'
        events.push name:'enterLink' , from:'waitToShow' , to:'waitToShow'
        events.push name:'enterLink' , from:'waitToHide' , to:'visible'
        events.push name:'showTimer' , from:'waitToShow' , to:'visible'
        events.push name:'exitLink'  , from:'visible'    , to:'waitToHide'
        events.push name:'exitLink'  , from:'waitToShow' , to:'init'
        events.push name:'enterPopo' , from:'waitToHide' , to:'visible'
        events.push name:'exitPopo'  , from:'visible'    , to:'waitToHide'
        events.push name:'hideTimer' , from:'waitToHide' , to:'init'

        @stateMachine = StateMachine.create

            initial: 'init'

            events : events

            error: (eventName, from, to, args, errorCode, errorMessage) ->
                console.log '  event ' + eventName + ' was naughty :- ' + errorMessage

            callbacks:

                onenterwaitToShow: (event,from,to) =>
                    # console.log '  _onenterwaitToShow',event, from, to
                    if from == 'init'
                        @_startShowTimer()
                        # this.stateMachine.showTimer()

                onentervisible: (event,from,to) =>
                    # console.log '  _onentervisible', event, from, to
                    if from == 'waitToShow'
                        @_moveTo()
                        @_show()
                    else if from == 'waitToHide'
                        window.clearTimeout(@hideTimeout)
                        if @_lastEnteredTargetView != @_currentTargetView
                            @_moveTo()

                onenterwaitToHide: (event,from,to) =>
                    # console.log '  _onenterwaitToHide', event, from, to
                    @_startHideTimer()
                    # this.stateMachine.hideTimer()

                onenterinit: (event,from,to) =>
                    # console.log '  _onenterinit', event, from, to
                    if from == 'waitToHide'
                        @_hide()
                    else if from == 'waitToShow'
                        window.clearTimeout(@showTimeout)


    _moveTo:() ->
        @_currentTargetView = @_lastEnteredTargetView
        target        = @_lastEnteredTargetView
        topFileInfo   = target.el.offsetTop
        scrollTop     = target.el.offsetParent.scrollTop
        @el.style.top = (topFileInfo - scrollTop) + 'px'


    _show: () ->
        @el.style.display = 'block'
        @el.classList.add('ease')


    _hide: () ->
        @el.style.display = 'none'
        @el.classList.remove('ease')


    _startShowTimer: ()->
        @showTimeout = window.setTimeout () =>
            @stateMachine.showTimer()
        , 700


    _startHideTimer: ()->
        @hideTimeout = window.setTimeout () =>
            @stateMachine.hideTimer()
        , 300


    onEnterLink: (targetView)->
        # console.log 'onEnterLink', @stateMachine.current
        @_lastEnteredTargetView = targetView
        @stateMachine.enterLink()


    onExitLink: (targetView)->
        # console.log 'onExitLink', @stateMachine.current
        @stateMachine.exitLink()
