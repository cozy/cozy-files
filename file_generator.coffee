fs   = require 'fs'
path = require "path"


###*
 * PARAMETERS
###
numberOfFilesToCreate = process.argv[2] or 5
content = fs.readFileSync './test/fixtures/files/test.txt'


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
      rmdir filename
    else
      # Remove file
      fs.unlinkSync filename
  fs.rmdirSync dir


###*
 * PREPARE THE FOLDER
###
try
    stats = fs.lstatSync('./test/fixtures/big-folder')
    console.log "dir exists, delete it"
    rmdirSync('./test/fixtures/big-folder')
catch e
    console.log "dir doesn't exists, nothing to do", e
finally
    console.log "create dir"
    fs.mkdirSync('./test/fixtures/big-folder')


###*
 * CREATE FILES
###
for i in [0..numberOfFilesToCreate] by 1
    # rank = if i < 10 then "0#{i}" else i
    rkTXT = Array(7 - "#{i}".length).join('0') + i
    filename = "test-#{rkTXT}"
    fs.writeFileSync "./test/fixtures/big-folder/#{filename}", content
