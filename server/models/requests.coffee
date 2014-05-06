americano = require 'americano-cozy'

module.exports =
    file:
        all: (doc) -> emit doc._id, doc
        byFolder: (doc) -> emit doc.path, doc
        byTag: (doc) -> emit(tag, doc) for tag in doc.tags or []

    folder:
        all: (doc) -> emit doc._id, doc
        byFolder: (doc) -> emit doc.path, doc
        byTag: (doc) -> emit(tag, doc) for tag in doc.tags or []

    contact:
        all: (doc) -> emit doc._id, doc

    user:
        all: (doc) -> emit doc._id, doc
