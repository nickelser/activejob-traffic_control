module ActiveJob
  module TrafficControl
    module Disable
      extend ::ActiveSupport::Concern

      DISABLED_REENQUEUE_DELAY = 60...60 * 10
      SHOULD_DROP = "drop".freeze
      SHOULD_DISABLE = "true".freeze

      private_constant :SHOULD_DROP, :SHOULD_DISABLE, :DISABLED_REENQUEUE_DELAY

      class_methods do
        def disable!(drop: false)
          cache_client.write(disable_key, drop ? SHOULD_DROP : SHOULD_DISABLE)
        end

        def enable!
          cache_client.delete(disable_key)
        end

        def disabled?
          cache_client && !cache_client.read(disable_key).nil?
        end

        def disable_key
          @disable_key ||= "traffic_control:disable:#{cleaned_name}".freeze
        end
      end

      included do
        include ActiveJob::TrafficControl::Base

        around_perform do |_, block|
          if cache_client
            disabled = cache_client.read(self.class.disable_key)

            if disabled == SHOULD_DROP
              drop("disabled".freeze)
            elsif disabled == SHOULD_DISABLE
              reenqueue(DISABLED_REENQUEUE_DELAY, "disabled".freeze)
            else
              block.call
            end
          else
            block.call
          end
        end
      end
    end
  end
end
