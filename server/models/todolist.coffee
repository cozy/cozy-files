americano = require 'americano-cozy'
Tree = require './tree'

module.exports = Todolist = americano.getModel 'TodoList',
    title : String
    path : String

Todolist.getOrCreateInbox = (callback) ->
    Todolist.all (err, lists) ->
        return callback err if err
        for list in lists when list.title is 'Inbox'
            return callback null, list.id

        # no "inbox" list found, create it
        inbox =
            parent_id: 'tree-node-all'
            title: 'Inbox'
            path: '["Inbox"]'

        Todolist.create inbox, (err, list) ->
            return callback err if err
            return callback 'cant create' unless list

            listNode =
                _id: list.id
                children: []
                data: "Inbox"
                attr: id: list.id

            callback2 = (err, tree) ->
                callback err, list.id

            Tree.all key: "TodoList", (err, trees) ->
                return callback err if err

                if trees.length is 0

                    tree =
                        type: "TodoList"
                        struct:
                            _id: "tree-node-all"
                            children: [listNode]
                            data: "All"
                            attr: id: "tree-node-all"

                    tree.struct = JSON.stringify tree.struct
                    Tree.create tree, callback2

                else
                    tree = trees[0]
                    struct = JSON.parse tree.struct
                    struct.children.push listNode
                    struct = JSON.stringify struct
                    tree.updateAttributes struct: struct, callback2
