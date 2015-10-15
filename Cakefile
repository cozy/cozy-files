{exec, spawn} = require 'child_process'
fs     = require 'fs'
path = require 'path'
fixtures = require 'cozy-fixtures'
logger = require('printit')
            date: false
            prefix: 'cake'

option '-f', '--file [FILE*]' , 'List of test files to run'
option '-d', '--dir [DIR*]' , 'Directory of test files to run'
option '-e' , '--env [ENV]', 'Run tests with NODE_ENV=ENV. Default is test'
option '-j' , '--use-js', 'If enabled, tests will run with the built files'
option '-s' , '--use-server', 'If enabled, starts a server'

options =  # defaults, will be overwritten by command line options
    file: no
    dir: no

# Grab test files of a directory recursively
walk = (dir, excludeElements = []) ->
    fileList = []
    list = fs.readdirSync dir
    if list
        for file in list
            if file and file not in excludeElements
                filename = "#{dir}/#{file}"
                stat = fs.statSync filename
                if stat and stat.isDirectory()
                    fileList2 = walk filename, excludeElements
                    fileList = fileList.concat fileList2
                else if filename.substr(-6) is "coffee"
                    fileList.push filename
    return fileList

taskDetails = '(default: ./tests, use -f or -d to specify files and directory)'
task 'tests:server', "Run tests #{taskDetails}", testsServer = (opts, callback) ->
    logger.options.prefix = 'cake:tests'
    files = []
    options = opts

    if options.dir
        dirList   = options.dir
        files = walk(dir, files) for dir in dirList
    if options.file
        files  = files.concat options.file
    unless options.dir or options.file
        files = walk "test"


    env = if options['env'] then "NODE_ENV=#{options.env}" else "NODE_ENV=test"
    env += " USE_JS=true" if options['use-js']? and options['use-js']
    logger.info "Running tests with #{env}..."
    command = "#{env} mocha " + files.join(" ") + " --reporter spec --colors "
    command += "--compilers coffee:coffee-script/register"
    exec command, (err, stdout, stderr) ->
        console.log stdout if stdout? and stdout.length > 0
        #console.log stderr if stderr? and stderr.length > 0
        if err?
            err = err
            console.log "Running mocha caught exception:\n" + err
            process.exit 1
        else
            console.log "Tests succeeded!"
            if callback?
                callback()
            else
                process.exit 0

task 'tests:client', 'Run tests for the client', testsClient=(opts, callback) ->
    logger.options.prefix = 'cake:tests:client'
    logger.info "Running client's tests..."

    if opts['use-server']? and opts['use-server']
        initializeServer = require path.join __dirname, './build/server'
    else
        initializeServer = (callback) -> callback()

    app = null
    fixtures.load
        dirPath: './test/fixtures',
        callback: ->
            initializeServer (app) ->
                if opts.file then files = opts.file.join ' '
                else files = 'client/tests/e2e'

                cmd = spawn 'casperjs', ['test', files]

                cmd.stdout.pipe process.stdout
                cmd.stderr.pipe process.stderr

                cmd.on 'exit', (code) ->
                    app.server.close() if app?
                    if code is 1
                        console.log "A least one test failed."
                        process.exit 1
                    else
                        console.log "Clients tests successfully runned!"
                        if callback?
                            callback()
                        else
                            process.exit 0

task 'tests', 'Run tests for client and server', (opts) ->
    testsServer opts, -> process.exit 0

# convert JSON lang files to JS
buildJsInLocales = ->
    path = require 'path'
    for file in fs.readdirSync './client/app/locales/'
        filename = './client/app/locales/' + file
        template = fs.readFileSync filename, 'utf8'
        exported = "module.exports = #{template};\n"
        name     = file.replace '.json', '.js'
        fs.writeFileSync "./build/client/app/locales/#{name}", exported
        # server files
    for file in fs.readdirSync './server/locales/'
        filename = './server/locales/' + file
        template = fs.readFileSync filename, 'utf8'
        exported = "module.exports = #{template};\n"
        name     = file.replace '.json', '.js'
        fs.writeFileSync "./build/server/locales/#{name}", exported
        # add locales at the end of app.js
    exec "rm -rf build/client/app/locales/*.json"

buildJade = ->
    jade = require 'jade'
    srcPath = './build/server/views'
    buildFolder = (folderPath) ->
        for file in fs.readdirSync(folderPath)
            elemPath = "#{folderPath}/#{file}"
            unless fs.lstatSync(elemPath).isDirectory()
                template = fs.readFileSync elemPath, 'utf8'
                output = "var jade = require('jade/runtime');\n"
                output += "module.exports = " + jade.compileClient template, filename: elemPath
                name = file.replace '.jade', '.js'
                fs.writeFileSync "#{folderPath}/#{name}", output
            else
                buildFolder elemPath
    buildFolder srcPath



task 'build', 'Build CoffeeScript to Javascript', ->
    logger.options.prefix = 'cake:build'
    logger.info "Start compilation..."
    binCoffee = "./node_modules/.bin/coffee"
    command = "#{binCoffee} -cb --output build/server server && " + \
              "#{binCoffee} -cb --output build/ server.coffee && " + \
              "cp -r server/views build/server && " + \
              "rm -rf build/client && mkdir build/client && " + \
              # prepare the client build
              "cp ./server/views/index_build.jade client/app/assets/index.jade && " + \
              "cp ./server/views/404_build.jade client/app/assets/404.jade && " + \
              "cd client/ && brunch build --production && cd .. && " + \
              "rm client/app/assets/*.jade && " + \
              "rm build/server/views/*.js && " + \
              "rm build/server/views/*/*.js && " + \
              "mv build/client/public/*.jade build/server/views/ && " + \
              "rm -rf build/server/views/*_build.jade && " + \
              "mkdir -p build/client/app/locales/ && " + \
              "rm -rf build/client/app/locales/* && " + \
              "cp -R client/public build/client/ && " + \
              "rm -rf client/app/locales/*.coffee"

    exec command, (err, stdout, stderr) ->
        if err
            logger.error "An error has occurred while compiling:\n" + err
            process.exit 1
        else
            buildJsInLocales()
            buildJade()
            exec "rm -rf build/server/views/*.jade && rm -rf build/server/views/*/*.jade", ->
                logger.info "Compilation succeeded."
                process.exit 0
