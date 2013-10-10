Remote = require '../models/remote'


## Helpers ##

# Define random function for application's token
randomString = (length) ->
    string = ""
    while (string.length < length)
        string = string + Math.random().toString(36).substr(2)
    return string.substr 0, length

findRemote = (id, callback) ->
    Remote.find id, (err, remote) =>
        if err or not remote
            callback "Remote not found"
        else
            callback null, remote 

## Actions ##

# POST remotes/
module.exports.create = (req, res) ->
    remote = 
        password: randomString 32
    if req.body.login?
        remote.login = req.body.login
    else
        remote.login = randomString 8
    Remote.all (err, remotes) ->
        conflict = false
        for rem in remotes
            if rem.login is remote.login
                conflict = true
                res.send error:true, msg: "This folder already exists", 400
        if not conflict
            Remote.create remote, (err, newRemote) ->
                if err
                    res.send error: true, msg: "Server error while creating file.", 500
                else    
                    res.send newRemote, 200

# PUT remotes/:id
module.exports.update = (req, res) ->
	findRemote req.params.id, (err, remote) ->
        if err
            res.send error: true, msg: err, 404
        else
            req.body.password = remote.password
            remote.updateAttributes req.body, (err, newRemote) ->
                if err
                    res.send error: true, msg: "Server error while creating file.", 500
                else    
                    res.send newRemote, 200

# PUT remotes/:id/token
module.exports.updateToken = (req, res) ->
	findRemote req.params.id, (err, remote) ->
        if err
            res.send error: true, msg: err, 404
        else
            remote.password = randomString 32
            remote.updateAttributes remote, (err, newRemote) ->
                if err
                    res.send error: true, msg: "Server error while creating file.", 500
                else    
                    res.send newRemote, 200

# DELETE remotes/:id
module.exports.destroy = (req, res) ->
	findRemote req.params.id, (err, remote) ->
        if err
            res.send error: true, msg: err, 404
        else
            remote.destroy (err) ->
                if err
                    compound.logger.write err
                    res.send error: 'Cannot destroy file', 500
                else
                    res.send success: 'Remote succesfuly deleted', 200