# Testing Frameworks
chai = require 'chai'
expect = chai.expect
chai.should( )

# Imports
Redis = require 'redis'
async = require 'async'
SSSS = require '../lib/index.js'

describe 'Super Simple Stats Syndicate', ( ) ->
	r = Redis.createClient( )
	stat = null
	clock = null
	statCreated = null
	statChannel = '__testing'

	beforeEach ( done ) ->
		stat = new SSSS statChannel, done
		statCreated = new Date

	afterEach ( done ) ->
		stat.destroy done

	it 'should construct an empty set in Redis on creation', ( done ) ->
		async.waterfall [
			# Check stats:__testing:data is [0..59] = 0
			checkData = ( next ) ->
				r.hmget ["stats:#{statChannel}:data"].concat( [0..59] ), next

			# Check stats:__testing:currentMinute is current minute
			checkMinute = ( data, next ) ->
				# Test data
				expect data, 'Minute array'
					.to.have.property 'length', 60

				# TODO: Chai-things
				for row, i in data
					expect row, "Minute #{i}"
						.to.equal '0'

				# Get currentMinute
				r.get "stats:#{statChannel}:currentMinute", next

			# Check stats:__testing:currentDate is current date
			checkDate = ( data, next ) ->
				# Test data
				expect data, 'Date'
					.to.equal "#{( statCreated ).getMinutes( )}"

				# Get currentDate
				r.get "stats:#{statChannel}:currentDate", next

		], ( err, data ) ->
			# Test data
			d1 = new Date statCreated
			d2 = new Date data

			d1.setHours d1.getHours( ), d1.getMinutes( ), 0, 0
			d2.setHours d2.getHours( ), d2.getMinutes( ), 0, 0

			expect d1.getTime( ), 'Time'
				.to.equal d2.getTime( )

			done( )

	it 'should remove any keys from redis on destruction', ( done ) ->
		async.waterfall [
			# Destroy channel
			destroyChannel = ( next ) ->
				stat.destroy next

			# Check stats:__testing:data is gone
			checkData = ( data, next ) ->
				expect data, 'Destroy response'
					.to.equal 3

				r.exists "stats:#{statChannel}:data", next

			# Check stats:__testing:currentMinute is gone
			checkMinute = ( data, next ) ->
				expect data, 'Data existence'
					.to.equal 0

				r.exists "stats:#{statChannel}:currentMinute", next

			# Check stats:__testing:currentDate is gone
			checkDate = ( data, next ) ->
				expect data, 'Minute existence'
					.to.equal 0

				r.exists "stats:#{statChannel}:currentDate", next

		], ( err, data ) ->
			expect data, 'Date existence'
				.to.equal 0

			done( )

	it 'should increment the counter on ping', ( done ) ->
		time = new Date( )

		# Increment counter a few times
		async.map [0..9], ( ( i, next ) -> stat.ping next ), ( err, results ) ->
			# Check value of current minute using redis library
			r.hget "stats:#{statChannel}:data", time.getMinutes( ), ( err, data ) ->
				expect data, 'Ping count'
					.to.equal '10'

				done( )

	it 'should retrieve the correct value for the last minute', ( done ) ->
		# Increment counter a few times
		async.map [0..9], ( ( i, next ) -> stat.ping next ), ( err, results ) ->
			# Check value for current minute
			stat.pastMinute ( err, val ) ->
				expect val, 'Ping count'
					.to.equal 0

				done( )

	it 'should retrieve the correct value for the current minute', ( done ) ->
		# Increment counter a few times
		async.map [0..9], ( ( i, next ) -> stat.ping next ), ( err, results ) ->
			# Check value for current minute
			stat.pastMinute true, ( err, val ) ->
				expect val, 'Ping count'
					.to.equal 10

				done( )

	it 'should correctly compute the average for the last 5 minutes', ( done ) ->
		# TODO: Loop through a few minutes
		# TODO: Increment counter a few times
		# TODO: wait
		# TODO: Check average value for past 5 mins

		done( )

