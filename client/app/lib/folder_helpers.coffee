module.exports =

removeTralingSlash: (path) ->
    if path.slice(-1) is '/'
        return path.slice(0, -1)
    return path

dirName: (path) ->
    return path.split('/')[...-1].join('/')


getFolderPathParts: (path) ->
    return path.split('/').filter (x) -> x # remove empty last part

nestedDirs: (fileList) ->

    # list of folders to create
    dirs = []

    # cache the key of folders to prevent useless loops
    addedPath = []

    # make an object with keys paths, values nest level
    # from each files we build the tree to recreate it
    for file in fileList
        relPath = file.relativePath or file.mozRelativePath or file.webkitRelativePath
        parents = relPath.slice(0, relPath.lastIndexOf(file.name))

        # get an array of the folders making the file path
        foldersOfPath = parents.split('/')[...-1]
        while foldersOfPath.length > 0
            parent = foldersOfPath.join '/'
            if not (parent in addedPath)
                dirs.push path: parent, depth: foldersOfPath.length
                addedPath.push parent
                foldersOfPath.pop()
            else
                break

    # put them in a list, sorted by nest level
    dirs.sort (a, b) ->
        return a.depth - b.depth

    return (dir.path for dir in dirs)
