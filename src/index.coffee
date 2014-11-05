# Imports
redis = require 'redis'
async = require 'async'

###
# SuperSimpleSharedStats
#
# Simple stats aggregation backed by Redis
###
module.exports = class SuperSimpleSharedStats
	###
	# Constructor, Channel name should be the same for all clients contributing
	# or querying this stat
	###
	constructor: ( @channelName, callback ) ->
		@ready = false
		@redis = redis.createClient( )
		@currentDate = new Date( )
		@currentMinute = @currentDate.getMinutes( )
		@keys =
			'data': "stats:#{@channelName}:data"
			'minute': "stats:#{@channelName}:currentMinute"
			'date': "stats:#{@channelName}:currentDate"

		async.waterfall [
			createHour = ( next ) =>
				args = [@keys.data]
				for i in [0..59]
					args.push i
					args.push 0

				args.push next
				@redis.hmset.apply @redis, args

			createMinutePosition = ( status, next ) =>
				@redis.set @keys.minute, @currentMinute, next

			createDatePosition = ( status, next ) =>
				@redis.set @keys.date, @currentDate, next

		], ( err, results ) =>
			@ready = true
			callback?( )

	###
	# Removes the data regarding this stat from Redis
	###
	destroy: ( callback ) ->
		@redis.del @keys.data, @keys.minute, @keys.date, callback

	###
	# Internal method for ensuring that the correct minute is being incremented
	# and maintains the relevant local variables.
	###
	checkPosition: ( callback ) ->
		if not @ready
			return setTimeout ( ( ) => @checkPosition callback ), 100

		newDate = new Date( )
		newMinute = newDate.getMinutes( )

		async.waterfall [
			getCurrentMinute = ( next ) =>
				@redis.get @keys.minute, ( err, minute ) =>
					@redis.get @keys.date, ( err, date ) ->
						next null, minute, date

			updateMinuteIfNeeded = ( minute, date, next ) =>
				date = new Date( date )

				if ( newMinute isnt parseInt( minute ) ) and ( newDate > date )
					@currentMinute = newMinute
					@currentDate = newDate

					return @redis.set @keys.minute, newMinute, ( ) =>
						@redis.set @keys.date, newDate, ( ) =>
							@redis.hset @keys.data, @currentMinute, 0, next

				else if date > @currentDate
					@currentMinute = minute
					@currentDate = newDate

				next null, true

		], ( err, results ) ->
			callback? null, true

	###
	# Increment the counter for the current minute
	###
	ping: ( callback ) ->
		async.waterfall [
			@checkPosition.bind @

			incrementCounter = ( success, next ) =>
				@redis.hincrby @keys.data, @currentMinute, 1, next

		], ( err, data ) ->
			callback? null, data

	###
	# Responds with the count for the past minute
	###
	pastMinute: ( current = false, callback ) ->
		if typeof current is 'function'
			callback = current
			current = false

		minute = ( 59 + @currentMinute) % 60
		minute += 1	if current

		async.waterfall [
			@checkPosition.bind @

			getLastMinute = ( success, next ) =>
				@redis.hget @keys.data, minute, next

		], ( err, data ) ->
			callback? null, parseFloat data

	###
	# Responds with the average over the past sample period (default 5 mins)
	###
	avgPerMinute: ( samplePeriod = 5, callback ) ->
		if typeof samplePeriod is 'function'
			callback = samplePeriod
			samplePeriod = 5

		if samplePeriod > 59
			samplePeriod = 59

		async.waterfall [
			@checkPosition.bind @

			getMinutes = ( success, next ) =>
				args = [@keys.data]
				for i in [0...samplePeriod]
					args.push ( 59 + @currentMinute - i ) % 60

				args.push next
				@redis.hmget.apply @redis, args

		], ( err, data ) ->
			ret = ( data.reduce( ( ( a, b ) -> a + parseInt b ), 0 ) / samplePeriod )
			callback? null, parseFloat ret
