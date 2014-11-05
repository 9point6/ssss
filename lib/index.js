(function() {
  var SuperSimpleSharedStats, async, redis;

  redis = require('redis');

  async = require('async');


  /*
   * SuperSimpleSharedStats
   *
   * Simple stats aggregation backed by Redis
   */

  module.exports = SuperSimpleSharedStats = (function() {

    /*
    	 * Constructor, Channel name should be the same for all clients contributing
    	 * or querying this stat
     */
    function SuperSimpleSharedStats(channelName, callback) {
      var createDatePosition, createHour, createMinutePosition;
      this.channelName = channelName;
      this.ready = false;
      this.redis = redis.createClient();
      this.currentDate = new Date();
      this.currentMinute = this.currentDate.getMinutes();
      this.keys = {
        'data': "stats:" + this.channelName + ":data",
        'minute': "stats:" + this.channelName + ":currentMinute",
        'date': "stats:" + this.channelName + ":currentDate"
      };
      async.waterfall([
        createHour = (function(_this) {
          return function(next) {
            var args, i, _i;
            args = [_this.keys.data];
            for (i = _i = 0; _i <= 59; i = ++_i) {
              args.push(i);
              args.push(0);
            }
            args.push(next);
            return _this.redis.hmset.apply(_this.redis, args);
          };
        })(this), createMinutePosition = (function(_this) {
          return function(status, next) {
            return _this.redis.set(_this.keys.minute, _this.currentMinute, next);
          };
        })(this), createDatePosition = (function(_this) {
          return function(status, next) {
            return _this.redis.set(_this.keys.date, _this.currentDate, next);
          };
        })(this)
      ], (function(_this) {
        return function(err, results) {
          _this.ready = true;
          return typeof callback === "function" ? callback() : void 0;
        };
      })(this));
    }


    /*
    	 * Removes the data regarding this stat from Redis
     */

    SuperSimpleSharedStats.prototype.destroy = function(callback) {
      return this.redis.del(this.keys.data, this.keys.minute, this.keys.date, callback);
    };


    /*
    	 * Internal method for ensuring that the correct minute is being incremented
    	 * and maintains the relevant local variables.
     */

    SuperSimpleSharedStats.prototype.checkPosition = function(callback) {
      var getCurrentMinute, newDate, newMinute, updateMinuteIfNeeded;
      if (!this.ready) {
        return setTimeout(((function(_this) {
          return function() {
            return _this.checkPosition(callback);
          };
        })(this)), 100);
      }
      newDate = new Date();
      newMinute = newDate.getMinutes();
      return async.waterfall([
        getCurrentMinute = (function(_this) {
          return function(next) {
            return _this.redis.get(_this.keys.minute, function(err, minute) {
              return _this.redis.get(_this.keys.date, function(err, date) {
                return next(null, minute, date);
              });
            });
          };
        })(this), updateMinuteIfNeeded = (function(_this) {
          return function(minute, date, next) {
            date = new Date(date);
            if ((newMinute !== parseInt(minute)) && (newDate > date)) {
              _this.currentMinute = newMinute;
              _this.currentDate = newDate;
              return _this.redis.set(_this.keys.minute, newMinute, function() {
                return _this.redis.set(_this.keys.date, newDate, function() {
                  return _this.redis.hset(_this.keys.data, _this.currentMinute, 0, next);
                });
              });
            } else if (date > _this.currentDate) {
              _this.currentMinute = minute;
              _this.currentDate = newDate;
            }
            return next(null, true);
          };
        })(this)
      ], function(err, results) {
        return typeof callback === "function" ? callback(null, true) : void 0;
      });
    };


    /*
    	 * Increment the counter for the current minute
     */

    SuperSimpleSharedStats.prototype.ping = function(callback) {
      var incrementCounter;
      return async.waterfall([
        this.checkPosition.bind(this), incrementCounter = (function(_this) {
          return function(success, next) {
            return _this.redis.hincrby(_this.keys.data, _this.currentMinute, 1, next);
          };
        })(this)
      ], function(err, data) {
        return typeof callback === "function" ? callback(null, data) : void 0;
      });
    };


    /*
    	 * Responds with the count for the past minute
     */

    SuperSimpleSharedStats.prototype.pastMinute = function(current, callback) {
      var getLastMinute, minute;
      if (current == null) {
        current = false;
      }
      if (typeof current === 'function') {
        callback = current;
        current = false;
      }
      minute = (59 + this.currentMinute) % 60;
      if (current) {
        minute += 1;
      }
      return async.waterfall([
        this.checkPosition.bind(this), getLastMinute = (function(_this) {
          return function(success, next) {
            return _this.redis.hget(_this.keys.data, minute, next);
          };
        })(this)
      ], function(err, data) {
        return typeof callback === "function" ? callback(null, parseFloat(data)) : void 0;
      });
    };


    /*
    	 * Responds with the average over the past sample period (default 5 mins)
     */

    SuperSimpleSharedStats.prototype.avgPerMinute = function(samplePeriod, callback) {
      var getMinutes;
      if (samplePeriod == null) {
        samplePeriod = 5;
      }
      if (typeof samplePeriod === 'function') {
        callback = samplePeriod;
        samplePeriod = 5;
      }
      if (samplePeriod > 59) {
        samplePeriod = 59;
      }
      return async.waterfall([
        this.checkPosition.bind(this), getMinutes = (function(_this) {
          return function(success, next) {
            var args, i, _i;
            args = [_this.keys.data];
            for (i = _i = 0; 0 <= samplePeriod ? _i < samplePeriod : _i > samplePeriod; i = 0 <= samplePeriod ? ++_i : --_i) {
              args.push((59 + _this.currentMinute - i) % 60);
            }
            args.push(next);
            return _this.redis.hmget.apply(_this.redis, args);
          };
        })(this)
      ], function(err, data) {
        var ret;
        ret = data.reduce((function(a, b) {
          return a + parseInt(b);
        }), 0) / samplePeriod;
        return typeof callback === "function" ? callback(null, parseFloat(ret)) : void 0;
      });
    };

    return SuperSimpleSharedStats;

  })();

}).call(this);

//# sourceMappingURL=maps/index.js.map