require "test_helper"

module ActiveJob::TrafficControlTest
  def setup_globals
    $count = 0
  end

  class DisableTestJob < ActiveJob::Base
    def perform
      $count += 1
    end
  end

  class ThrottleTestJob < ActiveJob::Base
    throttle threshold: 2, period: 1.second, drop: true

    def perform
      sleep 0.5
      $count += 1
    end
  end

  class ThrottleWithKeyTestJob < ActiveJob::Base
    throttle threshold: 2, period: 1.second, drop: true, key: "throttle_test_key"

    def perform
      sleep 0.5
      $count += 1
    end
  end

  class ThrottleWithProcKeyTestJob < ActiveJob::Base
    throttle threshold: 2, period: 1.second, drop: true, key: -> (_) { "throttle_proc_job_name" }

    def perform
      sleep 0.5
      $count += 1
    end
  end

  class ThrottleNotDroppedTestJob < ActiveJob::Base
    throttle threshold: 2, period: 1.second, drop: false

    def perform
      sleep 0.5
      $count += 1
    end
  end

  class ConcurrencyTestJob < ActiveJob::Base
    concurrency 1, drop: true

    def perform
      sleep 0.5
      $count += 1
    end
  end

  class ConcurrencyNotDroppedTestJob < ActiveJob::Base
    concurrency 1, drop: false

    def perform
      sleep 0.5
      $count += 1
    end
  end

  class ConcurrencyWithKeyTestJob < ActiveJob::Base
    concurrency 1, drop: true, key: "concurrency_test_key"

    def perform
      sleep 0.5
      $count += 1
    end
  end

  class ConcurrencyWithProcKeyTestJob < ActiveJob::Base
    concurrency 1, drop: true, key: -> (_) { "concurrency_proc_job_name" }

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

  def throttle_helper(klass)
    t1 = Thread.new { klass.perform_now }
    t2 = Thread.new { klass.perform_now }
    t3 = Thread.new { klass.perform_now }
    [t1, t2, t3].map(&:join)
    sleep 0.5
    assert_equal 2, $count
    sleep 1
    klass.perform_now
    assert_equal 3, $count
  end

  def test_throttle
    throttle_helper(ThrottleTestJob)
  end

  def test_throttle_with_key
    throttle_helper(ThrottleWithKeyTestJob)
  end

  def test_throttle_with_proc_key
    throttle_helper(ThrottleWithProcKeyTestJob)
  end

  def test_throttle_not_dropped
    return unless ActiveJob::Base.queue_adapter == :async

    t1 = Thread.new { ThrottleNotDroppedTestJob.perform_now }
    t2 = Thread.new { ThrottleNotDroppedTestJob.perform_now }
    t3 = Thread.new { ThrottleNotDroppedTestJob.perform_now }
    [t1, t2, t3].map(&:join)
    sleep 0.5
    assert_equal 2, $count
    sleep 6
    assert_equal 3, $count
  end

  def concurrency_helper(klass)
    t1 = Thread.new { klass.perform_now }
    t2 = Thread.new { klass.perform_now }
    [t1, t2].map(&:join)
    sleep 0.5
    assert_equal 1, $count
    klass.perform_now
    assert_equal 2, $count
  end

  def test_concurrency
    concurrency_helper(ConcurrencyTestJob)
  end

  def test_concurrency_with_key
    concurrency_helper(ConcurrencyWithKeyTestJob)
  end

  def test_concurrency_with_proc_key
    concurrency_helper(ConcurrencyWithProcKeyTestJob)
  end

  def test_concurrent_not_dropped
    return unless ActiveJob::Base.queue_adapter == :async

    t1 = Thread.new { ConcurrencyNotDroppedTestJob.perform_now }
    t2 = Thread.new { ConcurrencyNotDroppedTestJob.perform_now }
    [t1, t2].map(&:join)
    assert_equal 1, $count
    sleep 6
    assert_equal 2, $count
  end

  def test_concurrency_is_not_inherited
    t1 = Thread.new { InheritedConcurrencyJob.perform_now }
    t2 = Thread.new { InheritedConcurrencyJob.perform_now }
    [t1, t2].map(&:join)
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

class RedisNamespacedTrafficControlTest < Minitest::Test
  include ActiveJob::TrafficControlTest

  def setup
    ActiveJob::TrafficControl.client = Redis::Namespace.new(:namespace, redis: Redis.new)
    setup_globals
  end
end

class RedisNamespacedPooldedTrafficControlTest < Minitest::Test
  include ActiveJob::TrafficControlTest

  def setup
    ActiveJob::TrafficControl.client = ConnectionPool.new(size: 5, timeout: 5) do
      Redis::Namespace.new(:namespace, redis: Redis.new)
    end
    setup_globals
  end
end
