fs   = require 'fs'
path = require "path"


###*
 * PARAMETERS
###
numberOfDirToCreate = process.argv[2] or 5
folderTargetPath      = './fixtures/big-folder-of-folders'
content               = fs.readFileSync './fixtures/files/test.txt'


###*
 * HELPERS
###
rmdirSync = (dir) ->
  list = fs.readdirSync dir
  for item in list
    filename = path.join dir, item
    stat = fs.statSync filename
    if filename in [".", ".."]
      # Skip
    else if stat.isDirectory()
      # Remove directory recursively
      rmdirSync filename
    else
      # Remove file
      fs.unlinkSync filename
  fs.rmdirSync dir


###*
 * PREPARE THE FOLDER
###
try
    stats = fs.lstatSync(folderTargetPath)
    console.log "dir exists, delete it"
    rmdirSync(folderTargetPath)
catch e

finally
    console.log "create dir"
    fs.mkdirSync(folderTargetPath)


# fs.readdirSync('./fixtures/big-folder-of-folder')

###*
 * CREATE DIRECTORIES
###
for i in [0..numberOfDirToCreate-1] by 1
    # rank = if i < 10 then "0#{i}" else i
    rkTXT = Array(7 - "#{i}".length).join('0') + i
    dirname = "test-#{rkTXT}"
    fs.mkdirSync folderTargetPath + '/' + dirname
    fs.writeFileSync folderTargetPath + '/' + dirname + '/afile.txt', content

console.log numberOfDirToCreate, 'directories created in', folderTargetPath + '/'
