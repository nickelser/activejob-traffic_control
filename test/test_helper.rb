$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

if ENV["CODECLIMATE_REPO_TOKEN"]
  require "codeclimate-test-reporter"
  ::SimpleCov.add_filter "helper"
  CodeClimate::TestReporter.start
end

require "active_job/traffic_control"
require "minitest/autorun"

def test_logger
  @logger ||= begin
    l = Logger.new(STDOUT)
    l.level = Logger::ERROR
    l
  end
end

ActiveJob::Base.queue_adapter = :async
