isAndroidCallLogExport = (firstline) ->
    firstline is 'date,type,number,name,number type,duration'

isIOSCallLogExport = (firstline) ->
    firstline.split("\t").length is 5

module.exports.parse = (log) ->
    lines = log.split /\r?\n/

    if isAndroidCallLogExport lines[0]
        out = []
        lines.shift()
        for line in lines
            [timestamp, direction, number, _, _, duration] = line.split(',')
            out.push {timestamp, direction, number, duration}
        return out

    else if isIOSCallLogExport lines[0]
        out = []
        for line in lines
            [direction, timestamp, duration, number, _] = line.split("\t")
            out.push {timestamp, direction, number, duration}
        return out

    else
        console.log "NEITHER"
        throw new Error "Format not parsable"