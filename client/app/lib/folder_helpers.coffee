module.exports =

  removeTralingSlash: (path) ->
    if path.slice(-1) is '/'
      return path.slice(0, -1)
    return path

  dirName: (path) ->
    return path.split('/')[...-1].join('/')

  nestedDirs: (fileList) ->
    levels = {}

    # make an object with keys paths, values nest level
    for file in fileList
      relPath = file.relativePath || file.mozRelativePath || file.webkitRelativePath
      parent = relPath.split(file.name)[0]
      nestLevel = parent.split('/').length - 1
      levels[parent] = nestLevel

    # put them in a list, sorted by nest level
    dirs = (path: path, nestLevel: levels[path] for path in Object.keys(levels))
    dirs.sort (a, b) ->
      return a.nestLevel - b.nestLevel

    return (dir.path for dir in dirs)
