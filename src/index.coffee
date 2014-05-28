# # Karma Browserify

# This plugin adds a `browserify` framework and preprocessor to the Karma test
# runner.

crypto = require 'crypto'
path = require 'path'
os = require 'os'
fs = require 'fs'
browserify = require 'browserify'
through = require 'through'
chokidar = require 'chokidar'
crypto = require('crypto')

# The dependency cache stores all browserify dependencies.
depsCache = []

# The global dependency bundle reference.
depsBundle = null

# The temporary `karma-browserify.js` file path.
tmp = null

# Debug mode adds sourcemaps to the bundle.
debug = false

# The safe configuration keys to apply to the browserify bundles.
configs = ['transform', 'ignore', 'external']

# Apply select keys from a configuration object to a browserify bundle.
applyConfig = (b, cfg) ->
  (b[c] v for v in [].concat cfg[c] if cfg?[c]? and b?[c]?) for c in configs

# Write the dependency bundle out to the temporary file.
writeDeps = (callback) ->
  depsBundle.bundle debug: debug, (err, depsContent) ->
    return err if err
    fs.writeFile tmp, depsContent, (err) ->
      return err if err
      callback() if callback?

# Watch the dependency files for changes.
watcher = null
watch = (file) ->
  return watcher.add file if watcher?
  watcher = chokidar.watch file
  watcher.on 'change', -> writeDeps()

# ## Framework

# The karma-browserify framework creates a global bundle for all browserify
# dependencies that are not top-level Karma files.
framework = (logger, files, config={}) ->
  log = logger.create 'preprocessor.browserify (framework)'
  # Create an empty temp file for the global dependency bundle and add it to the
  # Karma files list.
  # MUST create a unique name else different projects can interfer with each other.
  fileName = __dirname + '_karma-browerify.js'
  # Filename path could be > 255 chars in length so md5 it.
  # (http://stackoverflow.com/questions/1323013/what-are-the-chances-that-two-messages-have-the-same-md5-digest-and-the-same-sha)
  hashedFileName = crypto.createHash('md5').update(fileName).digest("hex")
  log.debug 'Writing to temp file: "%s".', hashedFileName
  tmp = path.join (if os.tmpdir then os.tmpdir() else os.tmpDir()), hashedFileName
  fs.writeFileSync tmp, ''
  files.unshift pattern: tmp, included: true, served: true, watched: true

  # Initialize a browserify bundle for the global dependencies and apply the
  # Karma configuration.
  depsBundle = configuredBrowserify undefined, config

  # Turn on debug if given in config.
  debug = config.debug

# ## Preprocessor
preprocessor = (logger, config={}) ->
  # Create a logger.
  log = logger.create 'preprocessor.browserify'

  # The preprocessor callback is called for each file that matches its pattern.
  (content, file, done) ->
    log.debug 'Processing "%s".', file.originalPath

    # Create a file-specific browserify bundle and apply the configuration.
    fileBundle = configuredBrowserify (path.normalize file.originalPath), config

    # Override the bundle's default dependency handling, adding all dependencies
    # to the dependency cache and excluding them from the file bundle by passing
    # a proxy module which requires the absolute dependency reference.
    deps = (opts) ->
      fileBundle.deps(opts).pipe through (row) ->
        if row.id isnt file.originalPath
          depsCache.push row.id unless row.id in depsCache
          row.source = "module.exports=require('#{fileBundle._hash row.id}');"
        @queue row

    # Build the file bundle.
    fileBundle.bundle deps: deps, (err, fileContent) ->
      # Add any new dependencies in the cache to the dependency bundle.
      added = false   # Keep track of whether we added any.
      for d in depsCache when d not in depsBundle.files
        # Expose the bundle with the absolute filename.
        depsBundle.require d, expose: d
        # Watch dependency files for changes if requested in the config.
        watch d if config.watch
        added = true  # Set the added flag.
      # Bail and write the file bundle unless new dependencies were added.
      return done fileContent unless added
      # Write out the dependency bundle.
      writeDeps -> done fileContent

configuredBrowserify = (files, config={}) ->
  options =
    entries: files and [].concat files
    extensions: config.extension or config.extensions or []
    noParse: config.noParse
  bundle = browserify options
  applyConfig bundle, config
  bundle

framework.$inject = ['logger', 'config.files', 'config.browserify']
preprocessor.$inject = ['logger', 'config.browserify']
module.exports =
  'preprocessor:browserify': ['factory', preprocessor]
  'framework:browserify': ['factory', framework]
