karma-browserify
================

[Browserify](http://browserify.org) for [Karma](http://karma-runner.github.io)


Requirements
------------

This module currently requires the `canary` version of Karma:

```sh
$ npm install 'karma@canary' --save-dev
```

Note that the Karma configuration file format has changed since `v0.8`. Use 
`karma init` to generate a fresh config.


Installation
------------

Install the module from Github:

```sh
$ npm install 'git+https://github.com/xdissent/karma-browserify.git' --save-dev
```

Add `browserify` to the `frameworks` and `preprocessor` keys in your 
Karma configuration:

```coffee
module.exports = (karma) ->
  karma.configure

    # frameworks to use
    frameworks: ['mocha', 'browserify']

    preprocessors:
      '**/*.coffee': 'coffee'
      'my/test/files/*': 'browserify'

    # ...
```


Options
-------

The plugin may be configured using the `browserify` key in your Karma config:

```coffee
module.exports = (karma) ->
  karma.configure

    browserify: 
      extension: ['.coffee']  # This is for future compatibility.
      ignore: [path.join __dirname, 'components/angular-unstable/angular.js']
      transform: ['coffeeify']
      watch: true   # Watches dependencies only (Karma watches the tests)

    # ...
```


Usage
-----

Just `require` modules from within tests as you normally would in Node:

```coffee
something = require '../some/module'

describe 'karma tests with browserify', ->

  it 'should gimme dat module', ->
    something.should.exist()
```

See the [example](https://github.com/xdissent/karma-browserify/tree/master/example)
for a simple working setup.
