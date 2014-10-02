Super Simple Shared Stats
=========================

A simple time-series counter aggregation/syndication library for node backed by Redis and nothing else. Ideal for keeping track of counts between several processes.

[![BuildStatus](https://secure.travis-ci.org/9point6/ssss.png?branch=master)](http://travis-ci.org/9point6/ssss)

Install
-------

    npm install ssss

Note that you need a Redis version 2.0.0 or higher.

Quick Guide
-----------
```javascript
// Import and create instance
var SSSS = require('ssss'),
    requests = new SSSS('requests');

// Simulate requests
(reqs = function() {
    requests.ping();
    setTimeout(reqs, 1000 * Math.random());
})();

// Output current average every
setInterval(function() {
    requests.avgPerMinute(function (err, count) {
        console.log(count, 'requests per minute');
    });
}, 10000);
```

License
-------
Copyright 2014 John Sanderson

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
