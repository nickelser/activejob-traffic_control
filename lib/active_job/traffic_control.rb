# frozen_string_literal: true

require "active_support"
require "suo"

require "active_job/traffic_control/version"

require "active_job/traffic_control/base"
require "active_job/traffic_control/concurrency"
require "active_job/traffic_control/disable"
require "active_job/traffic_control/throttle"

module ActiveJob
  module TrafficControl
    class << self
      attr_writer :cache_client
      attr_accessor :client_klass

      def cache_client
        @cache_client ||= begin
          if defined?(Rails.cache)
            Rails.cache
          else
            logger.error "defaulting to `ActiveSupport::Cache::MemoryStore`; please set"\
                         " `ActiveJob::TrafficControl.cache_client` to a `ActiveSupport::Cache` compatible class."
            ActiveSupport::Cache::MemoryStore.new
          end
        end
      end

      def logger
        ActiveJob::Base.logger
      end

      def client
        @client ||= begin
          logger.error "defaulting to Redis as the lock client; please set "\
                       " `ActiveJob::TrafficControl.client` to a Redis or Memcached client."
          @client_klass = Suo::Client::Redis
          Redis.new(url: ENV["REDIS_URL"])
        end
      end

      def client=(cli)
        @client = cli

        if client.respond_to?(:checkout) # handle ConnectionPools
          unwrapped_client = client.checkout
          @client_klass = client_class_type(unwrapped_client)
          client.checkin
        else
          @client_klass = client_class_type(client)
        end

        client
      end

      def client_class_type(client)
        if client.instance_of?(Dalli::Client)
          Suo::Client::Memcached
        elsif client.instance_of?(::Redis) || defined?(::Redis::Namespace) && client.instance_of?(::Redis::Namespace)
          Suo::Client::Redis
        else
          raise ArgumentError, "Unsupported client type: #{client}"
        end
      end
    end
  end
end
