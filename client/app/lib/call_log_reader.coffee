normalizeNumber = require 'lib/phone_number'


isAndroidCallLogExport = (firstline) ->
    firstline is 'date,type,number,name,number type,duration'

isAndroidSMSExport = (firstline) ->
    firstline is 'Date,Time,Type,Number,Name,Message'

isIOSCallLogExport = (firstline) ->
    firstline.split("\t").length is 5

parseDuration = (duration) ->
    hours = minutes = seconds = 0

    # "XX:YY:ZZ" format
    if (parts = duration.split ':').length is 3
        [hours, minutes, seconds] = parts

    # "X hours Y minutes Z seconds" format
    else switch (parts = duration.split ' ').length
        when 2 then [seconds, _] = parts
        when 4 then [minutes, _, seconds, _] = parts
        when 6 then [hours, _, minutes, _, seconds, _] = parts

    duration = hours * 3600 + minutes * 60 + seconds

#char by char csv parser
parseCSV = (csv, progress, callback, result = [[]], state = {}) ->
    console.log state
    i = state.i or -1
    field = state.field or ''
    quoted = state.quoted or false
    limit = i + 10000
    row = result.length-1
    while true
        i++

        if i > limit
            # give back control to "UI Thread" for 10ms every 10 000 chars
            # prevent freezing for very large csv files
            return setTimeout ->
                progress(i, csv.length)
                parseCSV csv, progress, callback, result, {i:i-1, field, quoted}
            , 10

        c = csv[i]

        unless c? # if EOF
            return callback null, result

        else if c is "\""
            if quoted
                if csv[i+1] is "\"" # "" --> "
                    field += c
                    i++
                else
                    quoted = false
            else
                quoted = true

        else if not quoted and c is ','
            result[row].push field
            field = ''

        else if not quoted and (c is "\r" or c is "\n")
            if field isnt ''
                result[row].push field
                row++
                result[row] = []
                field = ''

        else
            field += c


directionAlias =
    'in': 'INCOMING'
    'out': 'OUTGOING'


module.exports.parse = (log, context, callback, progress) ->
    firstline = log.split(/\r?\n/)[0]

    if isAndroidCallLogExport firstline
        parseCSV log, progress, (err, parsed) ->
            parsed.shift() # remove header line
            parsed.pop() # remove empty last line
            callback null, parsed.map (line) ->
                [timestamp, direction, number, _, _, duration] = line
                return {
                    type: 'VOICE'
                    direction
                    timestamp: Date.create(timestamp).toISOString()
                    remote: tel: normalizeNumber number, context
                    content : duration: parseDuration duration
                }

    else if isAndroidSMSExport firstline
        parseCSV log, progress, (err, parsed) ->
            parsed.shift()
            parsed.pop()
            out = []
            parsed.map (line) ->
                [date, time, direction, numbers, _, message] = line
                tstmp = Date.create(date + 'T' + time + '.000Z').toISOString()
                for number in numbers.split(';')
                    out.push
                        type: 'SMS'
                        direction : directionAlias[direction]
                        timestamp : tstmp
                        remote: tel: normalizeNumber number, context
                        content: message: message

            callback null, out

    else throw new Error "Format not parsable"