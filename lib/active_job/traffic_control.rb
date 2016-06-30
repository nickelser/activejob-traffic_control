require "active_job"
require "active_support/all"
require "suo"

require "active_job/traffic_control/version"

require "active_job/traffic_control/base"
require "active_job/traffic_control/concurrency"
require "active_job/traffic_control/disable"
require "active_job/traffic_control/throttle"

module ActiveJob
  module TrafficControl
    class << self
      attr_writer :logger, :cache_client
      attr_accessor :client_klass

      def logger
        @logger ||= begin
          if defined?(Rails)
            Rails.logger
          else
            Logger.new(STDOUT).tap do |logger|
              logger.formatter = -> (_, datetime, _, msg) { "#{datetime}: #{msg}\n" }
            end
          end
        end
      end

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

      def client
        @client ||= begin
          logger.error "defaulting to Redis as the lock client; please set "\
                       " `ActiveJob::TrafficControl.client` to a Redis or Memcached client,"
          @client_klass = Suo::Client::Redis
          Redis.new(url: ENV["REDIS_URL"])
        end
      end

      def client=(cli)
        @client = cli

        if client.instance_of?(Dalli::Client)
          @client_klass = Suo::Client::Memcached
        elsif client.instance_of?(::Redis)
          @client_klass = Suo::Client::Redis
        else
          raise ArgumentError, "Unsupported client type: #{klass}"
        end

        @client
      end
    end
  end
end
