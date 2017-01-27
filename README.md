# ActiveJob::TrafficControl [![Build Status](https://travis-ci.org/nickelser/activejob-traffic_control.svg?branch=master)](https://travis-ci.org/nickelser/activejob-traffic_control) [![Code Climate](https://codeclimate.com/github/nickelser/activejob-traffic_control/badges/gpa.svg)](https://codeclimate.com/github/nickelser/activejob-traffic_control) [![Test Coverage](https://codeclimate.com/github/nickelser/activejob-traffic_control/badges/coverage.svg)](https://codeclimate.com/github/nickelser/activejob-traffic_control) [![Gem Version](https://badge.fury.io/rb/activejob-traffic_control.svg)](http://badge.fury.io/rb/activejob-traffic_control)

Rate controls for your `ActiveJob`s, powered by [Suo](https://github.com/nickelser/suo), a distributed semaphore library backed by Redis or Memcached.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activejob-traffic_control'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activejob-traffic_control

## Usage

`ActiveJob::TrafficControl` adds three modules you can mixin to your job classes as needed, or to `ApplicationJob` if you are using ActiveJob 5+ (or you have created a base job class yourself).

```ruby
# to initialize the type of locking client (memcached vs. redis):
ActiveJob::TrafficControl.client = ConnectionPool.new(size: 5, timeout: 5) { Redis.new } # set poolthresholds as needed
# or, ActiveJob::TrafficControl.client = ConnectionPool.new(size: 5, timeout: 5) { Dalli::Client.new }
# or if not multithreaded, ActiveJob::TrafficControl.client = Redis.new
```

### `Throttle`

```ruby
class CanThrottleJob < ActiveJob::Base
  throttle threshold: 2, period: 1.second

  def perform
    # no more than two of `CanThrottleJob` will run every second
    # if more than that attempt to run, they will be re-enqueued to run in a random time
    # ranging from 1 - 5x the period (so, 1-5 seconds in this case)
  end
end
```

If you do not care about the job being re-enqueued (if it's scheduled to run otherwise, or dropping will have no ill effect), you can specify `drop: true` instead. The `drop: true` flag also applies to `Concurrency`, below.

```ruby
class CanThrottleAndDropJob < ActiveJob::Base
  throttle threshold: 2, period: 1.second, drop: true

  def perform
    # no more than two of `CanThrottleJob` will run every second
    # if more than that attempt to run, they will be dropped
  end
end
```

### `Concurrency`

```ruby
class ConcurrencyTestJob < ActiveJob::Base
  concurrency 5, drop: false

  def perform
    # only five `ConcurrencyTestJob` will ever run simultaneously
  end
end
```

### `Disable`

For `Disable`, you also need to configure the cache client:

```ruby
ActiveJob::TrafficControl.cache_client = Rails.cache.dalli # if using :dalli_store
# or ActiveJob::TrafficControl.cache_client = ActiveSupport::Cache.lookup_store(:dalli_store, "localhost:11211")
```

```ruby
class CanDisableJob < ActiveJob::Base
  def perform
    # you can pause this job from running by executing `CanDisableJob.disable!` (which will cause the job to be re-enqueued),
    # or have it be dropped entirely via `CanDisableJob.disable!(drop: true)`
    # enable it again via `CanDisableJob.enable!`
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nickelser/activejob-traffic_control. Please look at the `.rubocop.yml` for the style guide.

