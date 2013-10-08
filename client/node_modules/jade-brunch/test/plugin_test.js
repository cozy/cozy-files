var jade = require('jade');

describe('Plugin', function() {
  var plugin;

  beforeEach(function() {
    plugin = new Plugin({});
  });

  it('should be an object', function() {
    expect(plugin).to.be.ok;
  });

  it('should has #compile method', function() {
    expect(plugin.compile).to.be.an.instanceof(Function);
  });

  it('should compile and produce valid result', function(done) {
    var content = '!!! 5';
    var expected = '<!DOCTYPE html>';

    plugin.compile(content, 'template.jade', function(error, data) {
      expect(error).not.to.be.ok;
      expect(eval(data)()).to.equal(expected);
      done();
    });
  });
});
