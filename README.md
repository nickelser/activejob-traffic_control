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

### `Disable`

```ruby
ActiveJob::TrafficControl.client = ConnectionPool.new(size: 5, timeout: 5) { Redis.new } # set thresholds as needed

class CanDisableJob < ActiveJob::Base
  include ActiveJob::TrafficControl::Disable

  def perform
    # you can pause this job from running by executing `CanDisableJob.disable!` (which will cause the job to be re-enqueued),
    # or have it be dropped entirely via `CanDisableJob.disable!(drop: true)`
    # enable it again via `CanDisableJob.enable!`
  end
end
```

### `Throttle`

```ruby
class CanThrottleJob < ActiveJob::Base
  include ActiveJob::TrafficControl::Throttle

  throttle threshold: 2, period: 1.second, drop: true

  def perform
    # no more than two of `CanThrottleJob` will run every second
    # if more than that attempt to run, they will be dropped (you can set `drop: false` to have the re-enqueued instead)
  end
end
```

### `Concurrency`

```ruby
class ConcurrencyTestJob < ActiveJob::Base
  include ActiveJob::TrafficControl::Concurrency

  concurrency 5, drop: false

  def perform
    # only five `ConcurrencyTestJob` will ever run simultaneously
end
``

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nickelser/activejob-traffic_control. Please look at the `.rubocop.yml` for the style guide.

