# Compare file path to existing file paths. If it already exists, it return
# false else it returns true.
module.exports.checkIfPathAvailable = (fileInfo, files, exceptionId) ->
    fullPath = "#{fileInfo.path}/#{fileInfo.name}"
    for fileDoc in files
        fileFullPath = "#{fileDoc.path}/#{fileDoc.name}"
        if (fullPath is fileFullPath) and (fileDoc.id isnt exceptionId)
            return false
    return true
