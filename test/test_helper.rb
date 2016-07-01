$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

ENV["RACK_ENV"] = ENV["RAILS_ENV"] = "test"

if ENV["CODECLIMATE_REPO_TOKEN"]
  require "codeclimate-test-reporter"
  ::SimpleCov.add_filter "helper"
  CodeClimate::TestReporter.start
end

require "dalli"
require "redis"
require "connection_pool"
require "active_job/traffic_control"
require "minitest/autorun"

test_logger = begin
  l = Logger.new(STDOUT)
  l.level = Logger::ERROR
  l
end

begin
  ActiveJob::Base.queue_adapter = :async # ActiveJob 5
rescue => _
  ActiveJob::Base.queue_adapter = :inline
end

ActiveJob::Base.logger = test_logger
