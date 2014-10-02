'use strict'

# Imports
gulp = require 'gulp'
plugins = do require 'gulp-load-plugins'

# Paths for tasks
paths =
	'scripts': [ 'src/**/*.coffee' ]
	'tests': [ 'test/**/*.coffee' ]
	'output': [ 'lib/**/*.js' ]

# Error Handler
onError = ( err ) ->
	plugins.util.beep( )
	if err.stack
		console.error err.stack
	else
		console.error err

# Clean built stuff
gulp.task 'clean', ( cb ) ->
	require( 'rimraf' )( 'lib/', cb )

# Compile Application (Clean first)
gulp.task 'scripts', [ 'lint-coffee', 'clean' ], ( ) ->
	gulp.src paths.scripts
		.pipe plugins.plumber errorHandler: onError
		.pipe plugins.sourcemaps.init( )
		.pipe plugins.coffee( )
		.pipe plugins.sourcemaps.write './maps', 'sourceRoot': '/src'
		.pipe plugins.plumber.stop( )
		.pipe gulp.dest './lib'

# Test code
gulp.task 'test', [ 'scripts' ], ( ) ->
	gulp.src paths.tests, 'read': false
		.pipe plugins.mocha 'reporter': 'spec'

# Lint generated JavaScript
gulp.task 'lint-js', [ 'scripts' ], ( ) ->
	gulp.src paths.output
		.pipe plugins.jshint require( './package.json' ).jshintConfig
		.pipe plugins.jshint.reporter require 'jshint-stylish'

# Lint CoffeeScript
gulp.task 'lint-coffee', ( ) ->
	gulp.src paths.scripts
		.pipe plugins.coffeelint( )
		.pipe plugins.coffeelint.reporter 'default'

# Build
gulp.task 'build', [ 'scripts', 'test' ]

# Rerun the task when a file changes
gulp.task 'watch', ( ) ->
	gulp.start 'build'
	gulp.watch paths.scripts.concat( paths.tests ),	[ 'build' ]

# The default task (called when you run `gulp` from CLI)
gulp.task 'default', [ 'watch' ]
