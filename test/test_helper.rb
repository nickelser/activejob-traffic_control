$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

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

ActiveJob::Base.queue_adapter = :inline
ActiveJob::Base.logger = test_logger
