
###*
 * this module is in charge of displaying a photo gallery when an image is
 * clicked
###
module.exports = class Gallery

    ###*
     * will open the diaporama when a photo is clicked
     * @param  {BackboneModel} modelClicked Model of the file clicked
    ###
    show: (modelClicked) ->

        # 1/ preprare the div of a fake thumbnail (input for baguettebox.js)
        gallery = document.getElementById('gallery')
        if gallery is null
            gallery = document.createElement('div')
            gallery.id = 'gallery'
            gallery.style.display = 'none'
            document.body.appendChild gallery
        else
            gallery.innerHTML = ''

        # 2/ populate the div with the links to the photo to display
        a_toSimulateClick = null
        window.app.router.folderView.collection.forEach (model)=>
            if !model.isImage()
                return
            a      = document.createElement('a')
            a.href = model.getScreenUrl()
            gallery.appendChild a
            if model is modelClicked
                a_toSimulateClick = a

        # 3/ run baguetteBox
        window.baguetteBox.run '#gallery',
            captions  : true
            buttons   : 'auto'
            async     : false
            preload   : 2
            animation : 'slideIn'

        # 4/ launch the display of the diaporama. For that we have to simulate
        # a click on a thumbnail.
        event = document.createEvent('MouseEvent')
        event.initMouseEvent 'click', true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null
        event.preventDefault()
        a_toSimulateClick.dispatchEvent event

        return


