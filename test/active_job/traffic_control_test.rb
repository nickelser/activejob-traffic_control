require "test_helper"

module ActiveJob::TrafficControlTest
  def setup_globals
    $count = 0
  end

  class DisableTestJob < ActiveJob::Base
    include ActiveJob::TrafficControl::Disable

    def perform
      $count += 1
    end
  end

  class ThrottleTestJob < ActiveJob::Base
    include ActiveJob::TrafficControl::Throttle

    throttle threshold: 2, period: 1.second, drop: true

    def perform
      $count += 1
    end
  end

  class ConcurrencyTestJob < ActiveJob::Base
    include ActiveJob::TrafficControl::Concurrency

    concurrency 1, drop: true

    def perform
      sleep 0.5
      $count += 1
    end
  end

  class InheritedConcurrencyJob < ConcurrencyTestJob
    def perform
      $count += 1
    end
  end

  class EverythingBaseJob < ActiveJob::Base
    include ActiveJob::TrafficControl::Concurrency
    include ActiveJob::TrafficControl::Throttle
    include ActiveJob::TrafficControl::Disable

    def perform
      $count += 1
    end
  end

  def test_that_it_has_a_version_number
    refute_nil ::ActiveJob::TrafficControl::VERSION
  end

  def test_it_does_something_useful
    assert true
  end

  def test_disable
    DisableTestJob.perform_now
    assert_equal 1, $count
    DisableTestJob.disable!(drop: true)
    assert_equal true, DisableTestJob.disabled?
    DisableTestJob.perform_now
    assert_equal 1, $count
    DisableTestJob.enable!
    DisableTestJob.perform_now
    assert_equal 2, $count
  end

  def test_throttle
    t1 = Thread.new { ThrottleTestJob.perform_now }
    t2 = Thread.new { ThrottleTestJob.perform_now }
    t3 = Thread.new { ThrottleTestJob.perform_now }
    [t1, t2, t3].map(&:join)
    assert_equal 2, $count
    sleep 1
    ThrottleTestJob.perform_now
    assert_equal 3, $count
  end

  def test_concurrency
    t1 = Thread.new { ConcurrencyTestJob.perform_now }
    t2 = Thread.new { ConcurrencyTestJob.perform_now }
    [t1, t2].map(&:join)
    sleep 1
    assert_equal 1, $count
    ConcurrencyTestJob.perform_later
    sleep 1
    assert_equal 2, $count
  end

  def test_concurrency_is_not_inherited
    t1 = Thread.new { InheritedConcurrencyJob.perform_later }
    t2 = Thread.new { InheritedConcurrencyJob.perform_later }
    [t1, t2].map(&:join)
    sleep 1
    assert_equal 2, $count
  end

  def test_everything_at_once
    EverythingBaseJob.perform_now
    assert_equal 1, $count
  end
end

class MemcachedTrafficControlTest < Minitest::Test
  include ActiveJob::TrafficControlTest

  def setup
    ActiveJob::TrafficControl.client = Dalli::Client.new
    ActiveJob::TrafficControl.cache_client = ActiveSupport::Cache.lookup_store(:dalli_store, "localhost:11211")
    setup_globals
  end
end

class MemcachedPooledTrafficControlTest < Minitest::Test
  include ActiveJob::TrafficControlTest

  def setup
    ActiveJob::TrafficControl.client = ConnectionPool.new(size: 5, timeout: 5) { Dalli::Client.new }
    ActiveJob::TrafficControl.cache_client = ActiveSupport::Cache.lookup_store(:dalli_store, "localhost:11211", pool_size: 5)
    setup_globals
  end
end

class RedisTrafficControlTest < Minitest::Test
  include ActiveJob::TrafficControlTest

  def setup
    ActiveJob::TrafficControl.client = Redis.new
    setup_globals
  end
end

class RedisPooledTrafficControlTest < Minitest::Test
  include ActiveJob::TrafficControlTest

  def setup
    ActiveJob::TrafficControl.client = ConnectionPool.new(size: 5, timeout: 5) { Redis.new }
    setup_globals
  end
end
