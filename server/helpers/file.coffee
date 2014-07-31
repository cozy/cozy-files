downloader = require '../lib/downloader'

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

    # Put right headers in response, then stream file to the response.
    processAttachment: (req, res, next, download) ->
        file = req.file

        # Configure headers
        if download
            contentHeader = "attachment; filename=#{file.name}"
        else
            contentHeader = "inline; filename=#{file.name}"
        res.setHeader 'Content-Disposition', contentHeader
        res.setHeader 'Content-Length', file.size

        # Perform download with the lowel level node js api to avoid too much
        # memory consumption.
        downloader.download "/data/#{file.id}/binaries/file", (stream) ->
            if stream.statusCode is 200
                stream.pipefilter = (source, dest) ->
                    XSSmimeTypes = ['text/html', 'image/svg+xml']
                    if source.headers['content-type'] in XSSmimeTypes
                        dest.setHeader 'content-type', 'text/plain'
                stream.pipe res

            else if stream.statusCode is 404
                err = new Error 'An error occured while downloading the file: ' + \
                                'file not found.'
                err.status = 404
                next err

            else
                next new Error 'An error occured while downloading the file.'

    # Returns a file calss depending of the mime type. It's useful to render icons
    # properly.
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
