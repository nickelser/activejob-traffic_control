require "active_support/all"
require "suo"

require "active_job/traffic_control/version"

require "active_job/traffic_control/base"
require "active_job/traffic_control/concurrency"
require "active_job/traffic_control/disable"
require "active_job/traffic_control/throttle"

module ActiveJob
  module TrafficControl
    # def client=(client)
    #   @client = client

    #   if client.instance_of?(Dalli::Client)
    #     @client_klass = Suo::Client::Memcached
    #   elsif klass.instance_of?(::Redis)
    #     @client_klass = Suo::Client::Redis
    #   else
    #     raise ArgumentError, "Unsupported client type: #{klass}"
    #   end
    # end

    # def client; @client; end
    # def client_klass; @client_klass; end
  end
end
