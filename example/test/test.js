var helper = require('./support/helper');
var external = require('../lib/external');
var deep = require('../lib/deep');
var npm = require('methods');

describe('this example', function() {
  it('should import a helper module', function() { 
    expect(helper).toEqual('helper.js');
  });

  it('should import an external module', function() { 
    expect(external).toEqual('external.js');
  });

  it('should import an external module which imports a module', function() { 
    expect(deep.another).toEqual('another.js');
  });

  it('should import an npm module', function() { 
    expect(npm).toContain('propfind');
  });
});