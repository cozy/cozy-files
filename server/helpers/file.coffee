module.exports =

    # Ensure that:
    #
    # * all path starts with /
    # * except empty path which is an empty string.
    normalizePath: (path) ->
        if path is "/"
            path = ""
        else if path.length > 0 and path[0] isnt '/'
            path = "/#{path}"
        path

    # Returns a file calss depending of the mime type. It's useful to render
    # icons properly.
    getFileClass: (file) ->
        type = file.headers['content-type']
        switch type.split('/')[0]
            when 'image' then fileClass = "image"
            when 'application' then fileClass = "document"
            when 'text' then fileClass = "document"
            when 'audio' then fileClass = "music"
            when 'video' then fileClass = "video"
            else
                fileClass = "file"
        fileClass
