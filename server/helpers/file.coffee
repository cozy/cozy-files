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
        encodedFileName = encodeURIComponent file.name
        if download
            contentHeader = "attachment; " + \
                            "filename*=UTF8''#{encodedFileName}"
        else
            contentHeader = "inline; " + \
                            "filename*=UTF8''#{encodedFileName}"
        res.setHeader 'content-disposition', contentHeader

        # Perform download with the lowel level node js api to avoid too much
        # memory consumption.
        url = "/data/#{file.id}/binaries/file"
        requester = downloader.download url, (stream) ->
            if stream.statusCode is 200
                stream.pipefilter = (source, dest) ->
                    XSSmimeTypes = ['text/html', 'image/svg+xml']
                    if source.headers['content-type'] in XSSmimeTypes
                        dest.setHeader 'content-type', 'text/plain'

                # Set headers from data system response data.
                res.setHeader 'content-length', stream.headers['content-length']
                res.setHeader 'content-type', stream.headers['content-type']

                # when the client closes the connection before the stream ends,
                # closes the connection to the data system to prevent it from
                # crashing due to many connections opened
                req.on 'close', -> requester.abort()

                stream.pipe res

            else if stream.statusCode is 404
                message = 'An error occured while downloading the file: ' + \
                          'file not found.'
                err = new Error message
                err.status = 404
                next err

            else
                next new Error 'An error occured while downloading the file.'

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
