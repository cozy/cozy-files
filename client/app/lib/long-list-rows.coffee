################################################################################
# -- USAGE --
#
#   # creation :
#
#
#       viewportElement = $('.longListViewport')[0] # the viewport element
#
#       options =
#           # unit used for the dimensions (px,em or rem)
#           DIMENSIONS_UNIT   : 'em'
#
#           # Height reserved for each row (unit defined by DIMENSIONS_UNIT)
#           ROW_HEIGHT        : 2
#
#           # number of "screens" before and after the viewport in the buffer.
#           # (ex : 1.5 => 1+2*1.5=4 screens always ready)
#           BUFFER_COEF       : 3
#
#           # number of "screens" before and after the viewport corresponding to
#           # the safe zone. The Safe Zone is the rows where viewport can go
#           # without trigering the movement of the buffer.
#           # Must be smaller than BUFFER_COEF
#           SAFE_ZONE_COEF    : 2
#
#           # minimum duration between two refresh after scroll (ms)
#           THROTTLE          : 450
#
#           # max number of viewport height by seconds : beyond this speed the
#           # refresh is delayed to the next throttle
#           MAX_SPEED         : 1.5
#
#           # call back when a row of the buffer is moved and must be completly
#           # redecorated
#           onRowsMovedCB     : (rowsToDecorate)->
#               # rowsToDecorate  : [ {rank:Integer, el:Element} , ... ]
#               # Array of objects giving the rank and a reference to the
#               # element of the moved row.
#               # The array is sorted in order to optimize refresh (the most
#               # usefull to refresh is the first one)
#
#           # [optional] call back when a row of the buffer is created (the
#           first decoration might differ from others). If not provided,
#           onRowsMovedCB will be called instead.
#           onRowsCreatedCB   : (rowsToDecorate)->
#               # rowsToDecorate  : [ {rank:Integer, el:Element} , ... ]
#               # Array of objects giving the rank and a reference to the
#               # element of the moved row.
#               # The array is sorted in order to optimize refresh (the most
#               # usefull to refresh is the first one)
#
#
#
#       longList = new LongListRows(viewportElement, options)
#       doActions() ...
#
#
#   # if the the viewportElement is not initialy attached in the DOM, then call
#   resizeHandler when the viewportElement is attached :
#       longList.resizeHandler()
#
#   # to add initial new rows
#   # if some are already in, they will be removed
#       longList.initRows(nToAdd)
#
#   # when the height of the viewportElement changes :
#       longList.resizeHandler()
#
#   # to add a row
#       longList.addRow(fromRank)
#
#   # to remove a block of rows
#       longList.removeRows(rankOrElement, nToRemove)
#
#   # to remove one row
#       longList.removeRow(rankOrElement)
#
#   # to remove all rows
#       longList.removeAllRows()
#
#   # to get the element corresponding to a rank (null if the rank is not in the
#   # DOM)
#       longList.getRowElementAt(rank)
#
#   # To get elements of rows of the buffer after a certain rank.
#   # Returns an empty array if the rank is after the buffer.
#       getRowsAfter(rank)


module.exports = class LongListRows

################################################################################
## PUBLIC SECTION ##
#

    constructor: (@externalViewport$, @options ) ->
        @options.MAX_SPEED = @options.MAX_SPEED  * @options.THROTTLE / 1000
        @onRowsMovedCB     = @options.onRowsMovedCB
        if @options.onRowsCreatedCB
            @onRowsCreatedCB   = @options.onRowsCreatedCB
        else
            @onRowsCreatedCB   = @options.onRowsMovedCB
        ####
        # get elements (name ends with '$')
        @viewport$ = document.createElement('div')
        @viewport$.classList.add('viewport')
        @externalViewport$.appendChild(@viewport$)
        @rows$ = document.createElement('div')
        @rows$.classList.add('rows')
        @rows$.style.cssText = "padding-top: 0px; box-sizing: border-box;"
        @viewport$.appendChild(@rows$)
        ####
        # set viewport style
        @externalViewport$.style.display = 'flex'
        @viewport$.style.cssText = "flex: 1 1 0%;
            position: relative;
            overflow-x: hidden;
            overflow-y: auto;"
        ####
        # adapt buffer to the initial geometry
        @_DOM_controlerInit()


    # if some are already in, they will be removed. Will call onRowsMovedCB.
    # ! note : your data describing rows state must be updated before calling
    # this method, because onRowsMovedCB might be called => the data must be
    # up to date when redecoration will occur.
    initRows: (nToAdd) ->
        ##
        # remove all rows of the buffer
        @_initBuffer()
        # the buffer is empty, initialise it
        @_firstPopulateBuffer(nToAdd)


    # To add new rows. Might call onRowsMovedCB.
    # ! note : your data describing rows state must be updated before calling
    # this method, because onRowsMovedCB might be called => the data must be
    # up to date when redecoration will occur.
    # addRows: (fromRank, nToAdd) ->
    #     @_addRows(fromRank, nToAdd)


    # to add a new row. Might call onRowsMovedCB.
    # ! note : your data describing rows state must be updated before calling
    # this method, because onRowsMovedCB might be called => the data must be
    # up to date when redecoration will occur.
    addRow: (fromRank) ->
        @_addRow(fromRank)


    # to remove one row. Might call onRowsMovedCB.
    # rankOrElement can be an integer or the element of the row to delete.
    # ! note : your data describing rows state must be updated before calling
    # this method, because onRowsMovedCB might be called => the data must be
    # up to date when redecoration will occur.
    removeRow: (rankOrElement) ->
        @_removeRows(rankOrElement, 1)


    # to remove some lines. Might call onRowsMovedCB.
    # rankOrElement can be an integer or the element of the first row to delete.
    # ! note : your data describing rows state must be updated before calling
    # this method, because onRowsMovedCB might be called => the data must be
    # up to date when redecoration will occur.
    removeRows: (rankOrElement, nToRemove) ->
        @_removeRows(rankOrElement, nToRemove)

    # to remove all lines. Might call onRowsMovedCB.
    # ! note : your data describing rows state must be updated before calling
    # this method, because onRowsMovedCB might be called => the data must be
    # up to date when redecoration will occur.
    removeAllRows: () ->
        ##
        # remove all rows of the buffer
        @_initBuffer()

    # retuns the element corresponding to the row of the given rank or undefined
    # if this row is outside the buffer.
    getRowElementAt: (rank) ->
        row = @_getRowAt(rank)
        if row
            return row.el
        else
            return undefined

    ###*
         * return the current number of rows
     * @return {Number} Number of rows
    ###
    getLength: () ->


    ###*
     * get elements of rows of the buffer after a certain rank. Returns an empty
     * array if the rank is after the buffer.
     * @return {Array} [{rank:Integer, el:Element}, ...]
    ###
    getRowsAfter: () ->



    ###*
     * Methodes for tests, are defined in _DOM_controlerInit
    ###
    _test:
        goDownHalfBuffer:null
        goUpHalfBuffer:null
        getState:null
        getInternals:null
        unActivateScrollListener:null
        activateScrollListener:null



################################################################################
## PRIVATE SECTION ##




    ###*
     * This is the main procedure. Its scope contains all the functions used to
     * update the buffer and the shared variables between those functions. This
     * approach has been chosen for performance reasons (acces to scope
     * variables faster than to nested properties of objects). It's not an
     * obvious choice.
    ###
    _DOM_controlerInit: () ->
        #######################
        # global variables
        buffer                = null
        noScrollScheduled     = true
        previousHeight        = null
        rowHeight             = null
        nMaxRowsInBufr        = null # theorical, buffer.nRows is the actual
        nRowsInBufrMargin     = null
        nRowsInSafeZoneMargin = null
        nRowsInSafeZone       = null
        nRowsInViewport       = null
        VP_firstRk            = null
        VP_lastRk             = null
        isDynamic             = false # true if more rows than elemts in buffer
        viewportHeight        = null
        lastOnScroll_Y        = null
        current_scrollTop     = null
        nRows                 = 0    # number of rows of the long list
        safeZone =
            startY         : null
            endY           : null
            firstVisibleRk : null
        # unit used for the dimensions (px,em or rem)
        DIMENSIONS_UNIT = @options.DIMENSIONS_UNIT
        # Height reserved for each row (unit defined by DIMENSIONS_UNIT)
        ROW_HEIGHT     = @options.ROW_HEIGHT
        # number of "screens" before and after the viewport in the buffer.
        # (ex: 1.5 => 1+2*1.5=4 screens always ready)
        BUFFER_COEF   = @options.BUFFER_COEF
        # number of "screens" before and after the viewport corresponding to
        # the safe zone. The Safe Zone is the lines where viewport can go
        # without trigering the movement of the buffer.
        # Must be smaller than BUFFER_COEF
        SAFE_ZONE_COEF  = @options.SAFE_ZONE_COEF
        # minimum duration between two refresh after scroll (ms)
        THROTTLE        = @options.THROTTLE
        # n = max number of viewport height by seconds : beyond this speed the
        # refresh is delayed to the nex throttle
        MAX_SPEED       = @options.MAX_SPEED



        _scrollHandler = (e) =>
            if noScrollScheduled and isDynamic
                lastOnScroll_Y = @viewport$.scrollTop
                setTimeout(_moveBuffer,THROTTLE)
                noScrollScheduled = false



        @_scrollHandler = _scrollHandler



        ###*
         * returns the font-size in px of a given element (context) or of the
         * root element of the document if no context is provided.
         * @param  {element} context Optionnal: an elemment to get the font-size
         * @return {integer} the font-size
        ###
        _getElementFontSize = ( context )->
            # Returns a number of the computed font-size, so in px
            # for the given context
            # or the root <html> element
            return parseFloat(
                getComputedStyle( context or document.documentElement ).fontSize
            )


        _remToPixels=(value)->
            return _emToPixels(value)



        _emToPixels=(value, context)->
            return Math.round(value * _getElementFontSize(context))



        _getDimInPixels = (value)=>
            switch DIMENSIONS_UNIT
                when 'px'
                    return value
                when 'em'
                    return _emToPixels(value, @viewport$)
                when 'rem'
                    return _remToPixels(value)



        ###*
         * called once for all during _DOM_controlerInit
         * computes the static parameters of the geometry
        ###
        _getStaticDimensions = () =>
            rowHeight         = _getDimInPixels(ROW_HEIGHT)



        ###*
         * Compute all the geometry after a resize or when the list in inserted
         * in the DOM.
         * _moveBuffer will be executed at the end except if the viewport has
         * no height (if not inserted in the dom for instance) or there is no
         * row
        ###
        _resizeHandler= ()=>
            # get dimensions.
            viewportHeight = @viewport$.clientHeight

            # the viewport has no height : geometry can not be computed
            # except if some initial width and height has been given
            if viewportHeight <= 0
                if @initialHeight
                    viewportHeight = @initialHeight
                else
                    return false

            # if the height of viewport has not change, we can directly adapt
            # buffer
            if viewportHeight == previousHeight and nRows != 0
                _moveBuffer()
                return
            previousHeight  = viewportHeight

            # compute the theorical buffer (theorical because there might not
            # need of such a buffer if there is not many rows added)
            nRowsInViewport   = Math.ceil(viewportHeight/rowHeight)
            nRowsInBufrMargin = Math.round(BUFFER_COEF * nRowsInViewport)
            nMaxRowsInBufr       = nRowsInViewport + nRowsInBufrMargin*2

            # compute the safe zone
            nRowsInSafeZoneMargin = Math.round(SAFE_ZONE_COEF * nRowsInViewport)
            nRowsInSafeZone       = nRowsInViewport + nRowsInSafeZoneMargin*2

            # check there are enough rows to fill the buffer
            if nRows <= nMaxRowsInBufr
                isDynamic = false
            else
                isDynamic = true

            # check if there are some rows of the buffer to create or delete
            if buffer
                deltaRows = Math.min(nRows,nMaxRowsInBufr) - buffer.nRows
                if deltaRows < 0
                    # delete deltaRows (arbitrary at the bottom of the buffer)
                    _deleteBufferRows(-deltaRows)
                else if deltaRows > 0
                    # create deltaRows (arbitrary at the bottom of the buffer)
                    _addBufferRows(deltaRows)

            if nRows != 0
                _moveBuffer()

        @resizeHandler = _resizeHandler


        _deleteBufferRows = (nToDelete)=>
            currentRow = buffer.last
            index = nToDelete - 1
            nDeleted = 1
            loop
                console.log nDeleted
                @rows$.removeChild(currentRow.el)
                nDeleted++
                currentRow = currentRow.next
                break unless index--
            buffer.last       = currentRow
            buffer.lastRk    -= nToDelete
            buffer.first.next =   currentRow
            currentRow.prev   = buffer.first
            buffer.nRows     -= nToDelete

        ###*
         * @param {Integer} add nToAdd rows at the bottom of the buffer
         *     {Row}:
         *          prev : {Row}
         *          next : {Row}
         *          el   : {Element}
         *          rank : {Integer}
        ###
        _addBufferRows = (nToAdd)=>
            rowsToDecorate = []
            startRk = buffer.lastRk
            prevCreatedRow = buffer.last
            for n in [1..nToAdd] by 1
                row$ = document.createElement('li')
                row$.setAttribute('class', 'long-list-row')
                row$.dataset.rank = startRk + n
                row$.style.height = rowHeight + 'px'
                @rows$.appendChild(row$)
                row =
                    prev : null
                    next : prevCreatedRow
                    el   : row$
                    rank : startRk + n
                prevCreatedRow.prev = row
                prevCreatedRow = row
                rowsToDecorate.push({rank:startRk+n; el:row$})
            # set the buffer
            buffer.last       = row
            buffer.first.next = row
            buffer.last.prev  = buffer.first
            buffer.lastRk     = row.rank
            buffer.nRows     += nToAdd
            # decorate the created rows
            @onRowsMovedCB(rowsToDecorate)


        ###*
         * Adapt the buffer when the viewport has moved out of the safe zone.
         * Launched by initRows and _scrollHandler
        ###
        _moveBuffer = (force) =>
            noScrollScheduled  = true

            ##
            # 1/ test speed, if too high, relaunch a _scrollHandler
            current_scrollTop = @viewport$.scrollTop
            speed = Math.abs(current_scrollTop - lastOnScroll_Y) / viewportHeight
            if speed > MAX_SPEED and not force
                # console.log "SPEED TO HIGH :-)"
                _scrollHandler()
                return

            ##
            # 2/ compute safeZone
            bufr = buffer
            VP_firstY  = current_scrollTop
            VP_firstRk = Math.floor(VP_firstY / rowHeight)
            VP_lastY   = current_scrollTop + viewportHeight
            VP_lastRk  = Math.floor(VP_lastY / rowHeight)
            SZ_firstRk = Math.max(VP_firstRk - nRowsInSafeZoneMargin , 0)
            SZ_lastRk  = SZ_firstRk + nRowsInSafeZone - 1
            # if nRows <= SZ_lastRk
            #     SZ_lastRk = nRows - 1
            #     SZ_firstRk = SZ_lastRk - nRowsInSafeZone + 1 # can not be lower
            #     # than 0, because that would meand there are less rows than in
            #     # the buffer, and in this case the scroll handler don't call
            #     # _moveBuffer

            ##
            # 3/ detect how the viewport is moving and how to adapt the buffer
            # console.log '\n======_moveBuffer, nRows=', nRows
            # console.log 'viewport firstRk', VP_firstRk, 'lastRk:', VP_lastRk
            # console.log 'safeZone firstRk', SZ_firstRk, 'lastRk:', SZ_lastRk
            # console.log 'initial buffer   firstRk', bufr.firstRk, 'lastRk:', bufr.lastRk

            nToMove = 0

            if bufr.lastRk < SZ_lastRk
                ##
                # 3.1/ the viewport is going down and its last line is bellow
                # the last line of the safeZone.
                # => compute new buffer

                newBfr_firstRk = Math.max(VP_firstRk - nRowsInBufrMargin, 0)
                newBfr_lastRk  = newBfr_firstRk + nMaxRowsInBufr - 1
                if nRows <= newBfr_lastRk
                    newBfr_lastRk = nRows - 1
                    newBfr_firstRk = newBfr_lastRk - nMaxRowsInBufr + 1 # can not be
                    # lower than 0, because that would meand there are less rows
                    # than in the buffer, and in this case the scroll handler
                    # don't call _moveBuffer

                # nToMove = number of rows to move by reusing rows from the top
                # of the buffer in order to fill its bottom
                nToMove = Math.min(newBfr_lastRk - bufr.lastRk, nMaxRowsInBufr)
                targetRk  = Math.max(bufr.lastRk + 1, newBfr_firstRk)

                # console.log 'direction: DOWN',         \
                #             'nToMove:'   + nToMove,    \
                #             'targetRk:'  + targetRk
                # console.log 'new buffer firstRk', newBfr_firstRk, \
                #             'lastRk', newBfr_lastRk

                if nToMove > 0
                    # console.log "there are nToMove=", nToMove,
                    #             "rows to move down after targetRk=", targetRk
                    elemtsToDecorate = _moveBufferToBottom(nToMove, targetRk)
                    @rows$.style.paddingTop = (bufr.firstRk*rowHeight)+'px'
                    @onRowsMovedCB(elemtsToDecorate)
                # else
                #     console.log "viewport goind DOWN but remain in =", nToMove,
                #                 "rows to move down after targetRk=", targetRk


            else if SZ_firstRk < bufr.firstRk
                ##
                # 3.2/ the viewport is going up and its last line is bellow
                # the last line of the safeZone.
                # => compute new buffer

                newBfr_firstRk = Math.max(VP_firstRk - nRowsInBufrMargin, 0)
                newBfr_lastRk  = newBfr_firstRk + nMaxRowsInBufr - 1

                # nToMove = number of rows to move by reusing rows from the
                # bottom of the buffer in order to fill its top
                nToMove  = Math.min(bufr.firstRk - newBfr_firstRk, nMaxRowsInBufr)
                targetRk = Math.min(bufr.firstRk - 1, newBfr_lastRk)

                # console.log 'direction: UO',           \
                #             'nToMove:'   + nToMove,    \
                #             'targetRk:'  + targetRk
                # console.log 'new buffer firstRk', newBfr_firstRk, \
                #             'lastRk', newBfr_lastRk

                if nToMove > 0
                    # console.log "there are nToMove=", nToMove,
                    #             "rows to move UP before targetRk=", targetRk
                    elemtsToDecorate = _moveBufferToTop(nToMove, targetRk)
                    @rows$.style.paddingTop = (bufr.firstRk*rowHeight)+'px'
                    @onRowsMovedCB(elemtsToDecorate)
                # else
                #     console.log "viewport goind DOWN but remain in =", nToMove,
                #                 "rows to move down after targetRk=", targetRk


            # console.log 'moved rows', nToMove
            # console.log 'final buffer   firstRk', bufr.firstRk, 'lastRk:', bufr.lastRk

        @_moveBuffer = _moveBuffer


        ###*
         * The buffer has been initialized, now we will create its rows elements
         * The buffer lists all the created rows, keep a reference on the first
         * (top most) and the last (bottom most) row.
         * The buffer is a closed double linked chain.
         * Each element of the chain is a "row" with a previous (prev) and next
           (next) element.
         * "closed" means that buffer.last.prev == buffer.first
         * Buffer data structure :
             first   : {row}    # top most row
             firstRk : {integer} # y of the first row of the buffer
             last    : {row}    # bottom most row
             lastRk  : {integer} # y of the last row of the buffer
             nRows   : {integer} # number of rows in the buffer
        ###
        _firstPopulateBuffer  = (nToAdd) =>
            # set nRows and init the height of the rows element
            nRows = nToAdd
            @rows$.style.height = nRows*rowHeight + 'px'
            @viewport$.scrollTop = 0
            # create the rows elements of the buffer
            bufr = buffer
            nToCreate = Math.min(nRows, nMaxRowsInBufr)
            firstCreatedRow = {}
            prevCreatedRow  = firstCreatedRow
            rowsToDecorate = []
            for n in [1..nToCreate] by 1
                row$ = document.createElement('li')
                row$.setAttribute('class', 'long-list-row')
                row$.dataset.rank = n-1
                row$.style.height = rowHeight + 'px'
                @rows$.appendChild(row$)
                row =
                    prev : null
                    next : prevCreatedRow
                    el   : row$
                    rank : n - 1
                prevCreatedRow.prev = row
                prevCreatedRow = row
                rowsToDecorate.push({rank:n-1;el:row$})
            # set the buffer
            if nToAdd == 0
                bufr.first   = null
                bufr.firstRk = -1
                bufr.last    = null
                bufr.lastRk  = -1
                bufr.nRows   = null
            else
                bufr.first   = firstCreatedRow.prev
                bufr.firstRk = 0
                bufr.last    = row
                bufr.first.next = bufr.last
                bufr.last.prev  = bufr.first
                bufr.lastRk  = row.rank
                bufr.nRows   = nToCreate
            # check if the long list is dynamic
            if nMaxRowsInBufr < nRows
                isDynamic = true
            else
                isDynamic = false


            @onRowsCreatedCB(rowsToDecorate)

        @_firstPopulateBuffer = _firstPopulateBuffer


        ###*
         * Add a new row in the current long list.
         * If the insertion is before the buffer or into the buffer, the
         * impacted rows are modified (their rank is increased by nToAdd)
         * If some rows are inserted
         * @param {integer} fromRank first rank where a row will be added
        ###
        _addRow = (fromRank)->
            # console.log 'LongList._addRow', fromRank
            if nRows == 0
                @_firstPopulateBuffer(1)
                return
            ##
            # update nRows
            nRows++
            if nRows <= nMaxRowsInBufr
                isDynamic = false
            else
                isDynamic = true
            ##
            # Case A: After the insertion there will be at most the
            # maximum nomber of rows in the buffer (nRows <= nMaxRowsInBufr)
            # We will just add a row in the buffer and create an element
            if nRows <= nMaxRowsInBufr

                ##
                # Case A.1: the insertion is at rank 0
                if fromRank == 0
                    row$ = document.createElement('li')
                    row$.setAttribute('class', 'long-list-row')
                    row$.style.height = rowHeight + 'px'
                    @rows$.insertBefore(row$, @rows$.firstChild)
                    row =
                        prev : buffer.first
                        next : buffer.last
                        el   : row$
                        rank : 0
                    # set the buffer
                    buffer.first.next = row
                    buffer.last.prev  = row
                    buffer.first      = row
                    buffer.lastRk++
                    buffer.nRows++
                    # adapt ranks of the rows of the buffer
                    last = buffer.last
                    row  = buffer.first
                    currentRk = 0
                    loop
                        row.rank = currentRk
                        row.el.dataset.rank = currentRk
                        break if row == last
                        row = row.prev
                        currentRk += 1
                    # redecorate created row
                    @rows$.style.height = nRows*rowHeight + 'px'
                    @onRowsCreatedCB([{el:row$,rank:0}])
                    return

                ##
                # Case A.2: the insertion is in the middle of the buffer,
                # including potentially the last row of the buffer
                else if fromRank <= buffer.lastRk
                    row$ = document.createElement('li')
                    row$.setAttribute('class', 'long-list-row')
                    row$.style.height = rowHeight + 'px'
                    rowOfInsertion = buffer.getRow(fromRank)
                    @rows$.insertBefore(row$, rowOfInsertion.el)
                    next = rowOfInsertion.next
                    row =
                        prev : rowOfInsertion
                        next : next
                        el   : row$
                        rank : fromRank
                    next.prev = row
                    rowOfInsertion.next = row
                    # set the buffer
                    buffer.lastRk++
                    buffer.nRows++
                    # adapt ranks of the rows of the buffer
                    last = buffer.last
                    row  = row
                    currentRk = fromRank
                    loop
                        row.rank = currentRk
                        row.el.dataset.rank = currentRk
                        break if row == last
                        row = row.prev
                        currentRk += 1
                    # redecorate created row
                    @rows$.style.height = nRows*rowHeight + 'px'
                    @onRowsCreatedCB([{el:row$,rank:fromRank}])
                    return

                ##
                # Case A.3: insertion of a new row after the last row of the
                # buffer
                else if fromRank == buffer.lastRk + 1
                    row$ = document.createElement('li')
                    row$.setAttribute('class', 'long-list-row')
                    row$.style.height = rowHeight + 'px'
                    row$.dataset.rank = fromRank
                    @rows$.appendChild(row$)
                    row =
                        prev : buffer.first
                        next : buffer.last
                        el   : row$
                        rank : fromRank
                    # set the buffer
                    buffer.first.next = row
                    buffer.last.prev  = row
                    buffer.last       = row
                    buffer.lastRk++
                    buffer.nRows++
                    # redecorate created row
                    @rows$.style.height = nRows*rowHeight + 'px'
                    @onRowsCreatedCB([{el:row$,rank:fromRank}])
                    return

                ##
                # fromRank is higher than buffer.lastRank + 1 : error
                else
                    return undefined

            ##
            # Case B: After the insertion there will at least one more row than
            # the maximum in the buffer (nRows == nMaxRowsInBufr + 1)

            ##
            # case B.1 : The insertion is before the buffer, first row included,
            # then just shift down the buffer of one row
            if fromRank <= buffer.firstRk
                scrollTop = @viewport$.scrollTop
                @rows$.style.height = nRows*rowHeight + 'px'
                # adapt viewport position only if it is not the target row is
                # not the first visible one (in this case the user will prefer
                # to see the shift of the rows)
                viewport_startRk = Math.floor(scrollTop / rowHeight)
                if fromRank != viewport_startRk
                    @viewport$.scrollTop = scrollTop + rowHeight

                # adapt ranks of the rows of the buffer
                last = buffer.last
                row   = buffer.first
                currentRk = row.rank + 1
                loop
                    row.rank = currentRk
                    row.el.dataset.rank = currentRk
                    break if row == last
                    row = row.prev
                    currentRk += 1
                # adapt first & last rank of the buffer
                buffer.firstRk += 1
                buffer.lastRk  += 1
                # adapt the buffer position
                @rows$.style.paddingTop = (buffer.firstRk*rowHeight)+'px'
                # we have to adapt buffer if the insertion rank is the first row
                # of the viewport (since viewport has not been moved earlier)
                if fromRank == viewport_startRk
                    _moveBuffer(true)

            ##
            # case B.2 : The insertion is into the buffer
            else if fromRank <= buffer.lastRk
                scrollTop = @viewport$.scrollTop
                viewport_startRk = Math.floor(scrollTop / rowHeight)
                # increase rows$ height
                @rows$.style.height = nRows*rowHeight + 'px'

                ##
                # case B.2.1 : insertion is into the buffer but before the
                # viewport
                # => we will shift up the top of the buffer and reuse the first
                # row
                if fromRank < viewport_startRk
                    # => reuse the top row element
                    @_insertTopToRank(fromRank)
                    # move viewport and adjust buffer top
                    @viewport$.scrollTop = scrollTop + rowHeight
                    @rows$.style.paddingTop = (buffer.firstRk*rowHeight)+'px'
                    return

                ##
                # case B.2.2 : insertion is into the buffer but after the
                # first row of the viewport
                # => we will reuse rows from the bottom of the buffer
                else
                    # fromRank is not the first row of the buffer
                    # reuse the bottom row element
                    @_insertBottomToRank(fromRank)
                    return

            ##
            # case B.3 : The insertion is after the buffer
            else if buffer.lastRk < fromRank
                @rows$.style.height = nRows*rowHeight + 'px'
                return

        @_addRow = _addRow


        ###*
         * Move the first row of buffer to fromRank
         * fromRank must be after buffer.firstRk and before buffer.lastRk
         * @param  {Integer} fromRank the rank where first row will go
        ###
        @_insertTopToRank = (fromRank) ->
            rowOfInsertion = buffer.getRow(fromRank)
            elToMove = buffer.first.el
            @rows$.insertBefore(elToMove, rowOfInsertion.el)
            buffer.firstRk += 1
            rowToReUse = buffer.first
            if fromRank == buffer.firstRk
                # no need to move the row, already at its destination
            else
                # move the first row to the rank fromRank
                buffer.first = rowToReUse.prev
                buffer.first.next = buffer.last
                buffer.last.prev  = buffer.first
                next = rowOfInsertion.next
                next.prev = rowToReUse
                rowOfInsertion.next = rowToReUse
                rowToReUse.next = next
                rowToReUse.prev = rowOfInsertion
            # increase the rank of the rows in buffer after the fromRank
            # row (included)
            row = rowToReUse
            last = buffer.last
            rk = fromRank
            loop
                row.rank = rk
                row.el.dataset.rank = rk
                rk++
                break if row == last
                row = row.prev
            buffer.lastRk = rk - 1
            # redecorate moved row
            @onRowsMovedCB([{el:rowToReUse.el,rank:rowToReUse.rank}])



        @_insertBottomToRank = (fromRank) ->
            rowOfInsertion = buffer.getRow(fromRank)
            elToMove = buffer.last.el
            @rows$.insertBefore(elToMove, rowOfInsertion.el)
            rowToReUse = buffer.last
            if rowOfInsertion != buffer.last
                # move the last row to the rank fromRank
                rowToReUse = buffer.last
                buffer.last = rowToReUse.next
                buffer.last.prev = buffer.first
                buffer.first.next = buffer.last
                next = rowOfInsertion.next
                next.prev = rowToReUse
                rowOfInsertion.next = rowToReUse
                rowToReUse.next = next
                rowToReUse.prev = rowOfInsertion
                # increase the rank of the rows in buffer after the fromRank
                # row (included)
                row = rowToReUse
                last = buffer.last
                rk = fromRank
                loop
                    row.rank = rk
                    row.el.dataset.rank = rk
                    rk++
                    break if row == last
                    row = row.prev
            # redecorate moved row
            @onRowsMovedCB([{el:rowToReUse.el,rank:rowToReUse.rank}])



        ###*
         * Remove rows
         * @param  {Integer|Element} fromRank  Rank  of the first row to delete,
         *                           or reference to the element of the row.
         * @param  {Integer} nToRemove Number of rows to delete from fromRank
        ###
        _removeRows = (rankOrElement, nToRemove) ->
            # if fromRank is an element, get its rank
            if typeof rankOrElement == "number"
                fromRank = rankOrElement
            else
                fromRank = parseInt(fromRank.dataset.rank)
            # limit toRank to the highest rank
            toRank = fromRank + nToRemove - 1
            if toRank > nRows - 1
                toRank = nRows -1
                nToRemove = toRank - fromRank + 1
            # compute the new number of rows, delete all rows if nRows == 0
            nRows -= nToRemove
            if nRows < 1
                @removeAllRows()
            # check there are enough rows to fill the buffer
            if nRows <= nMaxRowsInBufr
                isDynamic = false
            else
                isDynamic = true
            # delete rows one by one
            scrollTopDelta = 0
            for rk in [fromRank..toRank] by 1
                # notice that we always delete the row of the same rank rank...
                scrollTopDelta += _removeRow(fromRank)
            @viewport$.scrollTop += scrollTopDelta


        ###*
         * Prerequisites :
         *    - nRows and isDynamic must have been updated before _removeRow is
         *    called
         *    - must NOT be called to remove the last row (dealt by _removeRows)
         * @return  {number} scrollTopDelta : delta in px that the scrollTop of
         *                   the viewport should vary.
        ###
        _removeRow = (fromRank) =>
            ##
            # case 1 : The deletion is before the buffer
            if fromRank < buffer.firstRk
                @rows$.style.height = nRows*rowHeight + 'px'
                # adapt ranks of the rows of the buffer
                first     = buffer.first
                row       = first
                currentRk = first.rank - 1
                buffer.firstRk = currentRk
                loop
                    row.rank = currentRk
                    row.el.dataset.rank = currentRk
                    row = row.prev
                    currentRk += 1
                    break if row == first
                # adapt last rank of the buffer
                buffer.lastRk  = currentRk - 1
                @rows$.style.paddingTop = (buffer.firstRk*rowHeight)+'px'
                # return the scrollTopDelta
                return - rowHeight

            ##
            # case 2 : The deletion is into the buffer
            else if fromRank <= buffer.lastRk
                scrollTop = @viewport$.scrollTop
                viewport_startRk = Math.floor(scrollTop / rowHeight)
                viewport_endRk = viewport_startRk + nRowsInViewport - 1

                ##
                # deletion is into the buffer but before the viewport
                # => adjust scrollTop in order not to move visible rows
                if fromRank < viewport_startRk
                    scrollTopDelta = - rowHeight
                # => otherwise don't change the scrollTop
                else
                    scrollTopDelta = 0

                # get row element
                row = _getRowAt(fromRank)
                # decrease rows$ height
                @rows$.style.height = nRows*rowHeight + 'px'

                ##
                # case 2.1
                # test if the row element can be reused on top of the buffer (ie
                # if there are rows above the buffer)
                # If yes, the element will be moved on top of the buffer and
                # redecorated
                if 0 < buffer.firstRk
                    first = buffer.first
                    last  = buffer.last
                    if row == last
                        buffer.first = last
                        buffer.last = last.next
                        @rows$.insertBefore(row.el, first.el)
                    else if row != first
                        prev         = row.prev
                        next         = row.next
                        prev.next    = next
                        next.prev    = prev
                        row.prev     = first
                        row.next     = last
                        first.next   = row
                        last.prev    = row
                        buffer.first = row
                        @rows$.insertBefore(row.el, first.el)
                    # adapt ranks of the rows of the buffer
                    first      = row
                    currentRow = row
                    currentRk  = buffer.firstRk - 1
                    buffer.firstRk = currentRk
                    loop
                        currentRow.rank = currentRk
                        currentRow.el.dataset.rank = currentRk
                        currentRow = currentRow.prev
                        currentRk += 1
                        break if currentRow == first
                    # adapt last rank of the buffer
                    buffer.lastRk  = currentRk - 1
                    @rows$.style.paddingTop = (buffer.firstRk*rowHeight)+'px'
                    # redecorate the only element really modified
                    @onRowsMovedCB([{el:row.el,rank:row.rank}])
                    return scrollTopDelta

                ##
                # case 2.2
                # the row element can be reused on the bottom of the
                # buffer (ie there are rows under the buffer)
                # The element will be moved at the bottom of the buffer and
                # redecorated
                else if buffer.lastRk < nRows
                    first = buffer.first
                    last  = buffer.last
                    if row == first
                        buffer.last  = first
                        buffer.first = first.prev
                        @rows$.appendChild(row.el)
                        firstImpactedRow = buffer.first
                    else if row != last
                        prev        = row.prev
                        next        = row.next
                        prev.next   = next
                        next.prev   = prev
                        row.prev    = first
                        row.next    = last
                        first.next  = row
                        last.prev   = row
                        buffer.last = row
                        @rows$.appendChild(row.el)
                        firstImpactedRow = prev
                    else # row == buffer.last
                        firstImpactedRow = row
                    # adapt ranks of the rows of the buffer
                    first      = buffer.first
                    currentRow = firstImpactedRow
                    currentRk  = fromRank
                    loop
                        currentRow.rank = currentRk
                        currentRow.el.dataset.rank = currentRk
                        currentRow = currentRow.prev
                        currentRk += 1
                        break if currentRow == first
                    # redecorate the only element really modified
                    @onRowsMovedCB([{el:row.el,rank:row.rank}])
                    return scrollTopDelta

                ##
                # case 2.3
                # There are no rows nor above nor under the buffer,
                # just destroy the row from the buffer.
                else
                    # the buffer is now smaller than the number of rows
                    isDynamic  = false
                    first = buffer.first
                    last  = buffer.last
                    if row == first
                        last.prev  = row.prev
                        buffer.first = row.prev
                        buffer.first.next = last
                        @rows$.removeChild(row.el)
                        firstImpactedRow = buffer.first
                    else if row != last
                        prev        = row.prev
                        next        = row.next
                        prev.next   = next
                        next.prev   = prev
                        @rows$.removeChild(row.el)
                        firstImpactedRow = prev
                    else # row == buffer.last ie it is the last row
                        buffer.last = last.next
                        buffer.last.prev = first
                        first.next = buffer.last
                        @rows$.removeChild(row.el)
                        firstImpactedRow = null
                    # adapt ranks of the rows of the buffer
                    if firstImpactedRow
                        first      = buffer.first
                        currentRow = firstImpactedRow
                        currentRk  = fromRank
                        loop
                            currentRow.rank = currentRk
                            currentRow.el.dataset.rank = currentRk
                            currentRow = currentRow.prev
                            currentRk += 1
                            break if currentRow == first
                    buffer.lastRk -= 1
                    buffer.nRows  -= 1
                    return scrollTopDelta


            ##
            # case 3 : The insertion is after the buffer
            else if buffer.lastRk < fromRank
                @rows$.style.height = nRows*rowHeight + 'px'
                return 0

        @_removeRows = _removeRows


        ###*
         * move `nToMove` rows from top of the buffer to its bottom and will
         * have their rank starting at `newRk`
         * @param  {Integer} nToMove Nomber of rows to move
         * @param  {Integer} newRk rank of insertion of the first element at the
         *                         bottom of the buffer
        ###
        _moveBufferToBottom= (nToMove, newRk)=>
            bufr = buffer
            # TODO : enhancement : fill elemtsToDecorate in order of interest
            # of decoration (decorate first the row visible in the viewport,
            # usefull for images that will take time to download after
            # decoration)
            # idea :
            # rowsToDecorateLast = []
            # if bufr.lastRk < VP_firstRk
            #     rowsToDecorateLast
            # ...
            # elemtsToDecorate = rowsToDecorateLast.join(elementsToDecorate1st)
            elemtsToDecorate = []
            row  = bufr.first
            for rk in [newRk..newRk+nToMove-1] by 1
                row.rank = rk
                row.el.dataset.rank = rk
                @rows$.appendChild(row.el)
                elemtsToDecorate.push({el:row.el,rank:rk})
                row = row.prev
            bufr.first   = row
            bufr.last    = row.next
            bufr.firstRk = bufr.first.rank
            bufr.lastRk  = rk - 1
            return elemtsToDecorate


        ###*
         * move `nToMove` rows from bottom of the buffer to its top and will
         * have their rank starting at `newRk`
         * @param  {Integer} nToMove Nomber of rows to move
         * @param  {Integer} newRk rank of insertion of the first element at the
         *                         top of the buffer
        ###
        _moveBufferToTop = (nToMove, newRk)=>
            bufr = buffer
            elemtsToDecorate = []
            row  = bufr.last
            firstEl = bufr.first.el
            for rk in [newRk..newRk-nToMove+1] by -1
                row.rank = rk
                row.el.dataset.rank = rk
                @rows$.appendChild(row.el)
                @rows$.insertBefore(row.el, firstEl)
                elemtsToDecorate.push({el:row.el,rank:rk})
                firstEl = row.el
                row     = row.next
            bufr.last    = row
            bufr.first   = row.prev
            bufr.lastRk  = bufr.last.rank
            bufr.firstRk = rk + 1
            return elemtsToDecorate



        ###*
         * Construct the buffer. It will be empty at the end, only ready to be
         * used.
         * The buffer :
         *     * lists all the created rows, eg rows represented in the
         *       DOM by an element.
         *     * keeps a reference on the first row (top most) and the last
         *      (bottom most) row.
         *     * is a closed double linked chain.
         * Each element of the chain is a {row} with a previous (prev) and next
           (next) element.
         * "closed" means that buffer.last.prev == buffer.first
         * data structure :

           {buffer} :
             first   : {row}      # top most row
             firstRk : {integer}  # y of the first row of the buffer
             last    : {row}      # bottom most row
             lastRk  : {integer}  # y of the last row of the buffer
             nRows   : {integer}  # number of rows in the buffer
             getRow  : {function} # (rank)-> returns the row if the
                 rank is in the buffer, null otherwise.
                 If the buffer is not empty, all elements are removed.

           {Row}:
                prev : {Row}
                next : {Row}
                el   : {Element}
                rank : {Integer}
        ###
        _initBuffer = () ->
            # if the buffer is not empty, remove all elements of rows$
            if buffer
                @rows$.innerHTML = ''
                @rows$.style.height = '0px'
                @rows$.style.paddingTop = '0px'

            buffer =
                first   : null   # top most row
                firstRk : -1     # rank of the first row of the buffer
                last    : null   # bottom most row
                lastRk  : -1     # rank of the last row of the buffer
                nRows   : null   # actual number of rows in the buffer
                getRow  : (rank)->
                    first = this.first
                    row   = first
                    loop
                        if rank == row.rank
                            return row
                        row = row.prev
                        break if row == first
                    return null
            nRows     = 0
            isDynamic = false
        @_initBuffer = _initBuffer


        ####
        # Get the dimensions (rowHeight)
        _getStaticDimensions()
        ####
        # compute the geometry
        _resizeHandler()
        ####
        # bind events
        @viewport$.addEventListener( 'scroll', _scrollHandler)

        ###*
         * retuns the element corresponding to the row of the given rank or null
         * if this row is outside the buffer.
        ###
        _getRowAt = (rank)->
            if rank < buffer.firstRk
                return null
            else if rank <= buffer.lastRk
                row = buffer.first
                i   = rank - buffer.firstRk
                while i--
                    row = row.prev
                return row
            else
                return null
        @_getRowAt = _getRowAt


        @getLength = () ->
            return nRows

        ###*
         * get an array of the rows elements in the buffer after rank (included)
         * @param  {Integer} rank Rank of the first row
         * @return {Array}      [{rank:Integer, el:Element}, ...], [] if the
         *                      rank is not in the buffer.
        ###
        _getRowsAfter = (rank)->
            res = []
            # the row is after the buffer, return empty array.
            if rank > buffer.lastRk
                return res
            # get the row
            first = buffer.first
            row = _getRowAt(rank)
            # the row is above the buffer : return all buffer
            if row == null
                row = buffer.first
            # fetch all the rows after and return
            loop
                res.push({el:row.el, rank:row.rank})
                row = row.prev
                break if row == first
            return res

        @getRowsAfter = _getRowsAfter




################################################################################
## FUNCTIONS FOR TESTS AND DEBUG ##
#

        _goDownHalfBuffer = (ratio) =>
            if typeof(ratio) != 'number'
                ratio = 0.5
            scrollTop = @viewport$.scrollTop
            bufferHeight = buffer.nRows * rowHeight
            @viewport$.scrollTop = scrollTop + Math.round(bufferHeight*ratio)
            # force _moveBuffer in order to remain sync (otherwise you have to
            # wait for the scroll event so that the buffer gets adapted)
            _moveBuffer(true)
        @_test.goDownHalfBuffer = _goDownHalfBuffer


        _goUpHalfBuffer = (ratio) =>
            if typeof(ratio) != 'number'
                ratio = 0.5
            scrollTop = @viewport$.scrollTop
            bufferHeight = buffer.nRows * rowHeight
            @viewport$.scrollTop = scrollTop - Math.round(bufferHeight*ratio)
        @_test.goUpHalfBuffer = _goUpHalfBuffer


        _getState = () =>
            current_scrollTop = @viewport$.scrollTop
            bufr = buffer
            VP_firstY  = current_scrollTop
            VP_firstRk = Math.floor(VP_firstY / rowHeight)
            VP_lastY   = current_scrollTop + viewportHeight
            VP_lastRk  = Math.floor(VP_lastY / rowHeight)
            SZ_firstRk = Math.max(VP_firstRk - nRowsInSafeZoneMargin , 0)
            SZ_lastRk  = SZ_firstRk + nRowsInSafeZone - 1
            state =
                buffer :
                    firstRk : buffer.firstRk
                    lastRk  : buffer.lastRk
                    nRows   : buffer.nRows
                viewport :
                    firstRk : VP_firstRk
                    lastRk  : VP_lastRk
                safeZone :
                    firstRk : SZ_firstRk
                    lastRk  : SZ_lastRk
                nRows          : nRows
                rowHeight      : rowHeight
                height         : parseInt(@rows$.style.height)
                nMaxRowsInBufr : nMaxRowsInBufr
                isDynamic      : isDynamic
            return state
        @_test.getState = _getState


        _getInternals = () =>
            return {buffer, @rows$, @viewport$}
        @_test.getInternals = _getInternals


        @_test.unActivateScrollListener = () =>
            @viewport$.removeEventListener( 'scroll', _scrollHandler )


        @_test.activateScrollListener = () =>
            @viewport$.addEventListener( 'scroll', _scrollHandler )


