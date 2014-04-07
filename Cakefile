fs = require 'fs'
{exec} = require 'child_process'
logger = require('printit')
            date: false
            prefix: 'cake'

option '-f' , '--file [FILE*]' , 'test file to run'
option '' , '--dir [DIR*]' , 'directory where to grab test files'
option '-d' , '--debug' , 'run node in debug mode'
option '-b' , '--debug-brk' , 'run node in --debug-brk mode (stops on first line)'
option '' , '--use-js', 'If enabled, tests will run with the built files'

options = # defaults, will be overwritten by command line options
    file : no
    dir : no
    debug : no
    'debug-brk' : no


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
    options = opts
    testFiles = []
    if options.dir
        dirList = options.dir
        testFiles = walk(dir, testFiles) for dir in dirList
    if options.file
        testFiles = testFiles.concat(options.file)
    if not(options.dir or options.file)
        testFiles = walk("test", [])
    runTests testFiles

task 'tests:client', 'run client tests through mocha', (opts) ->
    options = opts
    uiTestFiles = walk("client/test", [])
    runTests uiTestFiles


runTests = (fileList) ->
    env = if options['use-js']? and options['use-js'] then "USE_JS=true" else ""
    command = "#{env} mocha " + fileList.join(" ") + " "
    if options['debug-brk']
        command += "--debug-brk --forward-io --profile "
    if options.debug
        command += "--debug --forward-io --profile "
    command += " --reporter spec --require should --compilers coffee:coffee-script/register --colors"
    exec command, (err, stdout, stderr) ->
        if err
            console.log "Running mocha caught exception: \n" + err
            console.log stderr

        console.log stdout
        process.exit if err then 1 else 0


task "xunit", "", ->
    process.env.TZ = "Europe/Paris"
    command = "mocha "
    command += " --require should --compilers coffee:coffee-script -R xunit > xunit.xml"
    exec command, (err, stdout, stderr) ->
        console.log stdout


task "xunit:client", "", ->
    process.env.TZ = "Europe/Paris"
    command = "mocha client/test/*"
    command += " --require should --compilers coffee:coffee-script -R xunit > xunitclient.xml"
    exec command, (err, stdout, stderr) ->
        console.log stdout

task 'build', 'Build CoffeeScript to Javascript', ->
    logger.options.prefix = 'cake:build'
    logger.info "Start compilation..."
    command = "coffee -cb --output build/server server && " + \
              "coffee -cb --output build/ server.coffee && " + \
              "cp -r server/views build/server && " + \
              "rm -rf build/client && mkdir build/client && " + \
              "cp -r client/public build/client/"
    exec command, (err, stdout, stderr) ->
        if err
            logger.error "An error has occurred while compiling:\n" + err
            process.exit 1
        else
            logger.info "Compilation succeeded."
            process.exit 0