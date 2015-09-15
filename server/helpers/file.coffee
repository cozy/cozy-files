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


    # Factory to create comparator to sort the content of a folder based on
    # criterion and order.
    folderContentComparatorFactory: (criterion, order) ->

        # Default values
        CRITERION = criterion or 'name'
        ORDER = order or 'asc'

        return (f1, f2) ->
            t1 = f1.docType.toLowerCase()
            t2 = f2.docType.toLowerCase()

            if t1 is t2

                if CRITERION is 'name'
                    n1 = f1.name.toLocaleLowerCase()
                    n2 = f2.name.toLocaleLowerCase()
                else if CRITERION is "lastModification"
                    n1 = new Date(f1.lastModification).getTime()
                    n2 = new Date(f2.lastModification).getTime()
                else
                    n1 = f1[CRITERION]
                    n2 = f2[CRITERION]

                sort = if ORDER is 'asc' then -1 else 1
                if CRITERION is 'class' and n1 is n2

                    # Sort by name if the class is the same
                    n1 = f1.name.toLocaleLowerCase()
                    n2 = f2.name.toLocaleLowerCase()

                    # Get both file extensions
                    e1 = n1.split('.').pop()
                    e2 = n2.split('.').pop()

                    if e1 isnt e2
                        # Sort by file extension if they are different
                        if e1 > e2 then return -sort
                        if e1 < e2 then return sort
                        return 0

                # Sort normally
                if n1 > n2 then return -sort
                else if n1 < n2 then return sort
                else return 0

            else if t1 is 'file' and t2 is 'folder'
                return 1
            else # t1 is 'folder' and t2 is 'file'
                return -1
