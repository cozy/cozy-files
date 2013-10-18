isAndroidCallLogExport = (firstline) ->
    firstline is 'date,type,number,name,number type,duration'

isIOSCallLogExport = (firstline) ->
    firstline.split("\t").length is 5

parseDuration = (duration) ->
    hours = minutes = seconds = 0
    if (parts = duration.split ':').length is 3
        [hours, minutes, seconds] = parts
    else switch (parts = duration.split ' ').length
        when 2 then [seconds, _] = parts
        when 4 then [minutes, _, seconds, _] = parts
        when 6 then [hours, _, minutes, _, seconds, _] = parts
    duration = hours * 3600 + minutes * 60 + seconds

module.exports.parse = (log) ->
    lines = log.split /\r?\n/

    if isAndroidCallLogExport lines[0]
        lines.shift() # remove header line
        lines.pop() # remove empty last line

        return lines.map (line) ->
            [timestamp, direction, number, _, _, duration] = line.split(',')

            console.log timestamp, Date.create(timestamp)

            return {
                timestamp: Date.create(timestamp).toISOString()
                direction
                remote: tel: number
                content : duration: parseDuration duration
            }


    else if isIOSCallLogExport lines[0]
        return lines.map (line) ->
            [direction, timestamp, duration, number, _] = line.split("\t")

            return {
                timestamp: Date.create(timestamp).toISOString()
                direction
                remote: tel: number
                content : duration: parseDuration duration
            }

    else
        throw new Error "Format not parsable"