# frozen_string_literal: true

module ActiveJob
  module TrafficControl
    module Throttle
      extend ::ActiveSupport::Concern

      class_methods do
        def throttle(
          threshold:,
          period:,
          drop: false,
          key: nil,
          delay: period,
          min_delay_multiplier: 1,
          max_delay_multiplier: 5
        )
          raise ArgumentError, "Threshold needs to be an integer > 0" if threshold.to_i < 1
          raise ArgumentError, "min_delay_multiplier needs to be a number >= 0" unless min_delay_multiplier.is_a?(Numeric) && min_delay_multiplier >= 0
          raise ArgumentError, "max_delay_multiplier needs to be a number >= max_delay_multiplier" unless max_delay_multiplier.is_a?(Numeric) && max_delay_multiplier >= min_delay_multiplier
          raise ArgumentError, "delay needs to a number > 0 " unless delay.is_a?(Numeric) && delay > 0

          self.job_throttling = {
            threshold: threshold,
            period: period,
            drop: drop,
            key: key,
            delay: delay,
            min_delay_multiplier: min_delay_multiplier,
            max_delay_multiplier: max_delay_multiplier
          }
        end

        def throttling_lock_key(job)
          lock_key("throttle", job, job_throttling)
        end
      end

      included do
        include ActiveJob::TrafficControl::Base

        class_attribute :job_throttling, instance_accessor: false

        around_perform do |job, block|
          if self.class.job_throttling.present?
            lock_options = {
              resources: self.class.job_throttling[:threshold],
              stale_lock_expiration: self.class.job_throttling[:period]
            }

            with_lock_client(self.class.throttling_lock_key(job), lock_options) do |client|
              token = client.lock

              if token
                block.call
              elsif self.class.job_throttling[:drop]
                drop("throttling")
              else
                delay = self.class.job_throttling[:delay]
                min_delay_multiplier = self.class.job_throttling[:min_delay_multiplier]
                max_delay_multiplier = self.class.job_throttling[:max_delay_multiplier]
                reenqueue((delay * min_delay_multiplier)...(delay * max_delay_multiplier), "throttling")
              end
            end
          else
            block.call
          end
        end
      end
    end
  end
end
