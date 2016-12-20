:warning: __This repository is no longer maintained. It's the Files application for Cozy V2. We are actively developping a new Files application for Cozy V3. You can follow the development [here](https://github.com/cozy/cozy-files-v3), to test it and report bugs. We will only fix major security or safety issues on this repository.__


# [Cozy](https://cozy.io) Files

Cozy Files makes your file management easy. Main features are:

* File tree
* Files and folders upload.
* Files and folders sharing (via URLs)
* Files and folders search
* Files and folders tagging (and search by tag)

## Install

We assume here that the Cozy platform is correctly [installed](https://docs.cozy.io/en/host/install/)
 on your server.

You can simply install the Files application via the app registry. Click on the *Chose Your Apps* button located on the right of your Cozy Home.

From the command line you can type this command:

    cozy-monitor install files


## Contribution

You can contribute to the Cozy Files in many ways:

* Pick up an [issue](https://github.com/cozy/cozy-files/issues?state=open) and solve it.
* Translate it in [a new language](https://github.com/cozy/cozy-files/tree/master/client/app/locales).
* Allow to move a file from a folder to another.


## Hack

Hacking the Files app requires you [setup a dev environment](https://dev.cozy.io/#set-up-the-development-environment). Once it's done you can hack Cozy Files just like it was your own app.

    git clone https://github.com/cozy/cozy-files.git
    cd cozy-files
    npm install

Run it with:

    node build/server.js

Each modification of the server requires a new build, here is how to run a build:

    cake build

Each modification of the client requires a specific build too.

    cd client
    npm install
    npm install -g brunch
    brunch build

## Tests

Cozy Files manages files in your Cozy platform.

![Build
Status](https://travis-ci.org/cozy/cozy-files.png?branch=master)

To run tests, use the following command into the Cozy Files folder:

    npm test

That's how Travis run the tests and it's what should be working when pushing code.

To run the tests against the `build/` version of the code, you can use:

    npm run test:build

That will also run the tests on both the server and the client but you don't have to build your code each time since it will run them against `server/` and `client/` rather than `build/`.

If you only want to run the tests for the server, use

    npm run test:server

If you only want to run the tests for the client, use

    npm run test:client

Or
    cake tests:client

In order to run the tests, you must have the Data System started. Also, for client tests, you need to install [CasperJS](http://casperjs.org/)

There are two options that can be used:

* `--use-js` will run the tests based on the `build/` folder
* `--use-server` will start a server during client tests

## Icons

by [iconmonstr](http://iconmonstr.com/)
and [momentum](http://www.momentumdesignlab.com/)

Main icon by [Elegant Themes](http://www.elegantthemes.com/blog/freebie-of-the-week/beautiful-flat-icons-for-free).

## Contribute with Transifex

Transifex can be used the same way as git. It can push or pull translations. The config file in the .tx repository configure the way Transifex is working : it will get the json files from the client/app/locales repository.
If you want to learn more about how to use this tool, I'll invite you to check [this](http://docs.transifex.com/introduction/) tutorial.

## License

Cozy Files is developed by Cozy Cloud and distributed under the AGPL v3 license.

## What is Cozy?

![Cozy Logo](https://raw.github.com/cozy/cozy-setup/gh-pages/assets/images/happycloud.png)

[Cozy](https://cozy.io) is a platform that brings all your web services in the
same private space.  With it, your web apps and your devices can share data
easily, providing you
with a new experience. You can install Cozy on your own hardware where no one
profiles you.

## Community

You can reach the Cozy Community by:

* Chatting with us on IRC #cozycloud on irc.freenode.net
* Posting on our [Forum](https://forum.cozy.io/)
* Posting issues on the [Github repos](https://github.com/cozy/)
* Mentioning us on [Twitter](https://twitter.com/mycozycloud)
