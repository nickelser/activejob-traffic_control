require "test_helper"

class ActiveJob::TrafficControlTest < Minitest::Test
  $disable_count = 0
  $concurrency_count = 0
  $inherited_concurrency_count = 0
  $throttle_count = 0

  class DisableTestJob < ActiveJob::Base
    include ActiveJob::TrafficControl::Disable

    def perform
      $disable_count += 1
    end
  end

  class ThrottleTestJob < ActiveJob::Base
    include ActiveJob::TrafficControl::Throttle

    throttle threshold: 2, period: 1.second, drop: true

    def perform
      $throttle_count += 1
    end
  end

  class ConcurrencyTestJob < ActiveJob::Base
    include ActiveJob::TrafficControl::Concurrency

    concurrency 1, drop: true

    def perform
      sleep 0.5
      $concurrency_count += 1
    end
  end

  class InheritedConcurrencyJob < ConcurrencyTestJob
    def perform
      $inherited_concurrency_count += 1
    end
  end

  def setup
    ActiveJob::TrafficControl.logger = test_logger
  end

  def test_that_it_has_a_version_number
    refute_nil ::ActiveJob::TrafficControl::VERSION
  end

  def test_it_does_something_useful
    assert true
  end

  def test_disable
    DisableTestJob.perform_now
    assert_equal 1, $disable_count
    DisableTestJob.disable!(drop: true)
    assert_equal true, DisableTestJob.disabled?
    DisableTestJob.perform_now
    assert_equal 1, $disable_count
    DisableTestJob.enable!
    DisableTestJob.perform_now
    assert_equal 2, $disable_count
  end

  def test_throttle
    t1 = Thread.new { ThrottleTestJob.perform_now }
    t2 = Thread.new { ThrottleTestJob.perform_now }
    t3 = Thread.new { ThrottleTestJob.perform_now }
    [t1, t2, t3].map(&:join)
    assert_equal 2, $throttle_count
    sleep 1
    ThrottleTestJob.perform_now
    assert_equal 3, $throttle_count
  end

  def test_concurrency
    t1 = Thread.new { ConcurrencyTestJob.perform_now }
    t2 = Thread.new { ConcurrencyTestJob.perform_now }
    [t1, t2].map(&:join)
    sleep 1
    assert_equal 1, $concurrency_count
    ConcurrencyTestJob.perform_later
    sleep 1
    assert_equal 2, $concurrency_count
  end

  def test_concurrency_is_not_inherited
    t1 = Thread.new { InheritedConcurrencyJob.perform_later }
    t2 = Thread.new { InheritedConcurrencyJob.perform_later }
    [t1, t2].map(&:join)
    sleep 1
    assert_equal 2, $inherited_concurrency_count
  end
end
