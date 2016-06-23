module ActiveJob
  module TrafficControl
    module Disable
      include ActiveJob::TrafficControl::Base
      extend ::ActiveSupport::Concern

      DISABLED_REENQUEUE_DELAY = 60...60 * 10

      included do
        around_perform :apply_disable
      end

      def disable_key
        @disable_key ||= "traffic_control:disable:#{cleaned_name}".freeze
      end

      def apply_disable
        disabled = Rails.cache.read(disable_key)

        if disabled == SHOULD_DROP
          drop("disabled".freeze)
        elsif disabled == SHOULD_DISABLE
          reenqueue(DISABLED_REENQUEUE_DELAY, "disabled".freeze)
        else
          yield
        end
      end

      def disable!(drop: false)
        Rails.cache.write(disable_key, drop ? SHOULD_DROP : SHOULD_DISABLE)
      end

      def enable!
        Rails.cache.delete(disable_key)
      end

      private

      SHOULD_DROP = "drop".freeze
      SHOULD_DISABLE = "true".freeze
      private_constant :SHOULD_DROP
    end
  end
end
