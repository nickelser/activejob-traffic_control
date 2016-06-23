module ActiveJob
  module TrafficControl
    module Base
      extend ::ActiveSupport::Concern

      class_methods do
        def cleaned_name
          name.to_s.gsub(/\W/, "_")
        end
      end

      def cleaned_name
        self.class.cleaned_name
      end

      def reenqueue(range, reason)
        later_delay = rand(range).seconds
        retry_job(wait: later_delay)
        Rails.logger.error "Re-enqueing #{self.class.name} to run in #{later_delay}s due to #{reason}"
        ActiveSupport::Notifications.instrument "re_enqueue.active_job", job: self, reason: reason
      end

      def drop(reason)
        Rails.logger.error "Dropping #{self.class.name} due to #{reason}"
        ActiveSupport::Notifications.instrument "dropped.active_job", job: self, reason: reason
      end

      private

      def with_raw_client
        if ActiveJob::TrafficControl.client.respond_to?(:with)
          ActiveJob::TrafficControl.client.with do |pooled_client|
            yield pooled_client
          end
        else
          yield ActiveJob::TrafficControl.client
        end
      end

      def with_lock_client(key, options)
        yield Suo::Client::Redis.new(key, options.merge(client: Redis.new))
      end

      def with_lock_clientx(key, options)
        with_raw_client do |client|
          yield ActiveJob::TrafficControl.client_klass.new(key, options.merge(client: client))
        end
      end
    end
  end
end
