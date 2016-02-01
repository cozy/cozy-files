BaseView     = require '../lib/base_view'

module.exports = class TagsView2 extends BaseView


    events: ->
        'click .tag'          : 'tagClicked'
        'click .tag .deleter' : 'deleteTag'
        'focus input'         : 'onFocus'
        'blur input'          : 'onBlur'
        'keydown input'       : 'onKeyDown'


    inputTemplate: -> """
        <input type="text" placeholder="#{t('tag')}">
    """


    initialize: ->
        @tags              = []
        @lastHideInputTime = 0
        @lastSelectTime    = 0
        @input             = null # ref to the input element if created


    onBlur: (e) =>
        if @input
            @hideInput()
        e.stopPropagation()

        # comment previous lines and
        # un-comment the followin for debug so that the autocomplete suggestion
        # doesn't close when element looses focus
        # Tag to search the other place to un-comment : azeklh
        # @input.typeahead('open')


    onKeyDown: (e) =>
        val = @input.val()

        # ESC
        if e.keyCode is 27
            # don't use hideInput, otherwise there will also be a on blur event
            # and there would be two call to hideInput...
            if @lastNavigatedItem == null
                @input.blur()
            else
                @input.typeahead('open')

        # TAB, ENTER : add the tag in the file
        if val and e.keyCode in [9, 13]
            @tags ?= []
            if val in @tags
                return
            @tags.push val
            window.tags.push val
            window.tags.sort (a, b) ->
                return a.toLowerCase().localeCompare(b.toLowerCase())
            @setTags @tags
            @input.typeahead('val', '')
            @lastNavigatedItem = null
            e.preventDefault()
            e.stopPropagation()
            return

        # ENTER and no value
        if val is '' and e.keyCode is 13
            time = new Date()
            if time - @lastSelectTime < 200
                return
            @input.blur()

        #UP, DOWN
        if e.keyCode in [40, 38]
            # keep track of the items seen with UP & DOWN
            @lastNavigatedItem = val
        else
            @lastNavigatedItem = null


    tagClicked: (e) ->
        tag = e.target.dataset.value
        # simulate search
        $("#search-box").val("tag:#{tag}").trigger 'keyup'


    setTags: (newTags) =>
        @tags = newTags
        @tags ?= []
        @refresh()
        clearTimeout @saveLater
        @saveLater = setTimeout =>
            @model.save tags: @tags
        , 1000


    deleteTag: (e) =>
        tag = e.target.parentNode.dataset.value
        @setTags _.without @tags, tag
        e.stopPropagation()
        e.preventDefault()


    refresh: (model) =>
        if model?
            @model = model
            @tags  = @model.get('tags')
            @listenTo @model, 'change:tags', =>
                @tags = @model.get('tags')
                @refresh()

        @$('.tag').remove()
        html = ("""
                <li class="tag" data-value="#{tag}">
                    #{tag}
                    <span class="deleter fa fa-times"></span>
                </li>
            """ for tag in @tags or []).join ''
        @$el.prepend html


    hideInput: =>
        if !@input
            return
        @lastHideInputTime = new Date()
        @input.typeahead('destroy')
        @input.remove()
        @input = null


    showInput: =>
        # don't show if this one has been hidden less than 200ms before (happens
        # if you click on the show button while the input has focus)
        time = new Date()
        if time - @lastHideInputTime < 200
            return
        if @input
            @input.typeahead('open')
        else
            @$el.append(@inputTemplate)
            @input = @$el.children().last()
            @showAutoComp()


    showAutoComp: () =>
        @possibleTags = _.difference(window.tags,@tags)

        ###*
         * in charge to evaluate the items matching the query (string type by
         * the user in the input
        ###
        substringMatcher = (query, cb) =>
            items = @possibleTags
            lastQuery = query

            if query is ''
                cb items
                return

            # an array that will be populated with the item wich matches
            matches = []

            # regexs used to determine if a string matches
            queryWords = query.toLowerCase().trim().split(' ')
            regExpList = []
            for word in queryWords
                if !reg = regExpHistory[word]
                    reg = new RegExp( word.split('').join('.*?'), 'g' )
                    regExpHistory[word] = reg
                regExpList.push reg

            # iterate through the pool of strings to find those that matche
            # all the regexp
            for item in items
                itemMatched = true
                for regExp in regExpList
                    if not regExp.test(item.toLowerCase())
                        itemMatched = false
                        break
                    regExp.lastIndex = 0
                if itemMatched
                    matches.push item

            cb matches


        ###*
         * in charge to produce the html for a suggestion line
         * @param  {String} item the suggestion text
         * @return {String}      html string
        ###
        suggestionTemplator = (item)=>
            val = @input.typeahead('val')
            if val is ''
                return html = "<p>#{item}</p>"
            queryWords = val.toLowerCase().trim().split(' ')
            itemLC = item.toLowerCase()
            fullWordsToHighlight = Array(item.length)

            for word in queryWords
                wordRegexp = regExpHistory[word]
                wordRegexp.lastIndex = 0
                fullWordMatch_N = 0
                fuzzyWordsToHighlight = Array(item.length)

                # for each word of the query look for an occurence to
                # highlight
                while match = wordRegexp.exec(itemLC)
                    # if the occurence is a contiguous string, keep it
                    if match[0].length is word.length
                        fullWordMatch_N++
                        trackCharsToHighlight(itemLC, fullWordsToHighlight,match.index,word)
                    # else keep it only if so far there was no full match
                    else if fullWordMatch_N is 0
                        trackCharsToHighlight(itemLC, fuzzyWordsToHighlight,match.index,word)
                # if there were only fuzzy match, fusionnates the fuzzy
                # chars to highllight with the full match chars.
                if fullWordMatch_N is 0
                    for isToHighlight,n in fuzzyWordsToHighlight
                        if isToHighlight
                            fullWordsToHighlight[n] = true

            return html = highlightItem(item,fullWordsToHighlight)

        ###*
         * instanciation of the autocomplete (typeahead.js)
        ###
        @input.typeahead {
          hint      : true
          highlight : true
          minLength : 0
        },
          limit     : 20,
          name      : "tag",
          source    : substringMatcher,
          templates :
            suggestion: suggestionTemplator

        ###*
         * listen to selections (mouse click in the suggestions)
        ###
        @input.bind 'typeahead:select', (ev, suggestion) =>
            @lastSelectTime = new Date()
            @tags ?= []
            if suggestion in @tags
                return
            @tags.push suggestion
            # remove the chosen suggestion from the possible tags
            @possibleTags = _.without(@possibleTags,suggestion)
            @setTags @tags
            # force to evaluate the suggestions because the possible tags has changed
            @input.typeahead('val', 'qsfqsdgf')
            @input.typeahead('val', '')
            @lastNavigatedItem = null

        ###*
         * listen when the suggestions are closed in order to reopen it if it is
         * a click (select) that triggered the close.
        ###
        @input.bind 'typeahead:close', (ev, suggestion) =>
            time = new Date()
            if time - @lastSelectTime < 200
                @input.typeahead('open')
                return
            # un-comment for debug so that the autocomplete suggestion doesn't
            # close when element looses focus
            # Tag to search the other place to un-comment : azeklh
            # @input.typeahead('open')

        @input.focus()
        @lastNavigatedItem = null




###
    functions for the auto complete (highliths helpers)
###


regExpHistory = {}
lastQuery     = ''


trackCharsToHighlight = (item, charsToHighlight,startIndex,word)->
    charsToHighlight[startIndex] = true
    nChars = item.length
    charIndex = startIndex
    wordIndex = 1
    while charIndex < nChars
        char = item[charIndex]
        if  char is word[wordIndex]
            charsToHighlight[charIndex] = true
            if ++wordIndex >= word.length
                return
        charIndex++
    return


highlightItem = (item,charsToHighlight) ->
    res = '<p>'
    previousWasToHighlight = undefined
    for isToHighlight, n in charsToHighlight
        if isToHighlight is previousWasToHighlight
           res +=  item[n]
        else
            if previousWasToHighlight
                res += '</strong>' + item[n]
            else
                res += '<strong class="tt-highlight">' + item[n]
        previousWasToHighlight = isToHighlight
    if previousWasToHighlight
        return res += '</strong></p>'
    else
        return res += '</p>'
