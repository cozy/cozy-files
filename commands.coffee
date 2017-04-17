async = require 'async'
File = require './server/models/file'
Folder = require './server/models/folder'


die = (msg, err, code) ->
    console.log "Error", msg, err?.stack or err
    process.exit code

switch  process.argv[2]
    when 'reindex-all'

        File.all (err, files) ->
            die "cant get file list", err, 2 if err
            files ?= []
            async.eachSeries files, (file, next) ->
                file.index ['name'], (err) ->
                    die "index file #{file.path}", err, 3 if err
                    next err

            , (err) ->
                die "unknown error 1", err, 4 if err

                Folder.all (err, folders) ->
                    die "cant get file list", err, 2 if err
                    folders ?= []
                    async.eachSeries folders, (folder, next) ->
                        folder.index ['name'], (err) ->
                            die "index folder #{folder.path}", err, 3 if err
                            next err

                    , (err) ->
                        die "unknown error 2", err, 5 if err

                        console.log "It worked"
                        process.exit 0
    else
        console.log "Wrong command, available commands are"
        console.log "- reindex-all : force cozy-indexer to reindex"
        process.exit 1
