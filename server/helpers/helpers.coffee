module.exports =
    slugify: (text) ->
        text.replace(/[^-a-zA-Z0-9,&\s]+/ig, '')
        .replace(/-/gi, '_')
        .replace(/\s/gi, '-')

    noop: ->