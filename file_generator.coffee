fs = require 'fs'

content = fs.readFileSync './test/fixtures/files/test.txt'

numberOfFiles = process.argv[2] or 1000

for i in [0..numberOfFiles] by 1
    rank = if i < 10 then "0#{i}" else i
    filename = "test-#{rank}"
    fs.writeFileSync "./big-folder/#{filename}", content
