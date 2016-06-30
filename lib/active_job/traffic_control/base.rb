require "forwardable"

module ActiveJob
  module TrafficControl
    module Base
      extend ::ActiveSupport::Concern
      extend Forwardable

      def_delegators ActiveJob::TrafficControl, :logger, :cache_client, :client, :client_klass

      class_methods do
        def cleaned_name
          name.to_s.gsub(/\W/, "_")
        end

        def cache_client
          ActiveJob::TrafficControl.cache_client
        end
      end

      # convenience methods
      def cleaned_name
        self.class.cleaned_name
      end

      def reenqueue(range, reason)
        later_delay = rand(range).seconds
        retry_job(wait: later_delay)
        logger.error "Re-enqueing #{self.class.name} to run in #{later_delay}s due to #{reason}"
        ActiveSupport::Notifications.instrument "re_enqueue.active_job", job: self, reason: reason
      end

      def drop(reason)
        logger.error "Dropping #{self.class.name} due to #{reason}"
        ActiveSupport::Notifications.instrument "dropped.active_job", job: self, reason: reason
      end

      protected

      def with_raw_client
        if client.respond_to?(:with)
          client.with do |pooled_client|
            yield pooled_client
          end
        else
          yield client
        end
      end

      def with_lock_client(key, options)
        with_raw_client do |cli|
          yield client_klass.new(key, options.merge(client: cli))
        end
      end
    end
  end
end
