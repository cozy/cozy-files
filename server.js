// Generated by CoffeeScript 1.6.3
var americano, logwatch, port, start;

logwatch = require('./server/initializers/finglogwatch');

americano = require('americano');

start = function(port, callback) {
  return americano.start({
    name: 'Contacts',
    port: port
  }, function(app, server) {
    return logwatch(server, function(err) {
      return typeof callback === "function" ? callback(null, app, server) : void 0;
    });
  });
};

if (!module.parent) {
  port = process.env.PORT || 9114;
  start(port, function(err) {
    if (err) {
      console.log("Initialization failed, not starting");
      console.log(err.stack);
      return process.exit(1);
    }
  });
} else {
  module.exports = start;
}
