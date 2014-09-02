exports.config =

    paths:
        public: 'public'

    plugins:
        coffeelint:
            options:
                indentation: value:4, level:'error'

    conventions:
        vendor: /(vendor)|(_specs)(\/|\\)/ # do not wrap tests in modules

    files:
        javascripts:
            defaultExtension: 'coffee'
            joinTo:
                'javascripts/app.js': /^app/
                'javascripts/vendor.js': /^vendor/
                '../_specs/specs.js': /^_specs.*\.coffee$/
            order:
                before: [
                    # Backbone
                    'vendor/scripts/jquery-2.1.1.js',
                    'vendor/scripts/underscore.js',
                    'vendor/scripts/backbone.js',
                    # Twitter Bootstrap jquery plugins
                    'vendor/scripts/bootstrap.js',
                ]
                after: [
                ]
        stylesheets:
            defaultExtension: 'styl'
            joinTo:
                'stylesheets/app.css': /^app/
                'stylesheets/vendor.css': /^vendor/
            order:
                before: [
                    'vendor/styles/bootstrap.css'
                    'vendor/styles/bootstrap-responsive.css',
                ]
                after: []
        templates:
            defaultExtension: 'jade'
            joinTo: 'javascripts/app.js'

    plugins:
        jade:
            globals: ['t', 'moment']
    framework: 'backbone'
