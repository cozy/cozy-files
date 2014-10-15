fs     = require 'fs'
{exec} = require 'child_process'
logger = require('printit')
            date: false
            prefix: 'cake'

option '-f' , '--file [FILE*]' , 'test file to run'
option ''   , '--dir [DIR*]'   , 'directory where to grab test files'
option '-j' , '--use-js', 'If enabled, tests will run with the built files'

options =  # defaults, will be overwritten by command line options
    file        : no
    dir         : no

# Grab test files of a directory
walk = (dir, fileList) ->
    list = fs.readdirSync(dir)
    if list
        for file in list
            if file
                filename = dir + '/' + file
                stat = fs.statSync(filename)
                if stat and stat.isDirectory()
                    walk(filename, fileList)
                else if filename.substr(-6) == "coffee"
                    fileList.push(filename)
    return fileList

task 'tests', 'run server tests, ./test is parsed by default, otherwise use -f or --dir', (opts) ->
    options   = opts
    testFiles = []
    if options.dir
        dirList   = options.dir
        testFiles = walk(dir, testFiles) for dir in dirList
    if options.file
        testFiles  = testFiles.concat(options.file)
    if not(options.dir or options.file)
        testFiles = walk("tests", [])
    runTests testFiles

task 'tests:client', 'run client tests through mocha', (opts) ->
    exec "mocha-phantomjs client/_specs/index.html", (err, stdout, stderr) ->
        if err
            console.log "Running mocha caught exception: \n" + err
        console.log stdout


runTests = (fileList) ->
    env = " USE_JS=true" if options['use-js']? and options['use-js']

    command = "#{env} mocha " + fileList.join(" ") + " "
    command += " --globals setImmediate,clearImmediate"
    command += " --reporter spec --compilers coffee:coffee-script/register --colors"
    exec command, (err, stdout, stderr) ->
        if err
            console.log "Running mocha caught exception: \n" + err
        console.log stdout
        process.exit if err then 1 else 0

task 'build', 'Build CoffeeScript to Javascript', ->
    logger.options.prefix = 'cake:build'
    logger.info "Start compilation..."
    command = "coffee -cb --output build/server server && " + \
              "coffee -cb --output build/ server.coffee && " + \
              "rm -rf build/client && mkdir build/client && " + \
              # prepare the client build
              "cp ./client/index.jade ./build/client/index.jade && " + \
              "cp ./client/widget.jade ./build/client/widget.jade && " + \
              "cd client/ && brunch build --production && cd .."

    exec command, (err, stdout, stderr) ->
        if err
            logger.error "An error has occurred while compiling:\n" + err
            process.exit 1
        else
            logger.info "Compilation succeeded."
            process.exit 0
