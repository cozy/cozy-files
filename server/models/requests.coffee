americano = require 'americano-cozy'

module.exports =
    file:
        all: (doc) -> emit doc.slug, doc
        byFolder: (doc) -> emit doc.path, doc

    folder:
        all: (doc) -> emit doc.slug, doc
        byFolder: (doc) -> emit doc.path, doc
