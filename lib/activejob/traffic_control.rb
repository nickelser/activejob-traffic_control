require "active_job/traffic_control"

ActiveSupport.on_load(:active_job) do
  include ActiveJob::TrafficControl::Concurrency
  include ActiveJob::TrafficControl::Throttle
  include ActiveJob::TrafficControl::Disable
end
