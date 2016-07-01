# frozen_string_literal: true

module ActiveJob
  module TrafficControl
    module Throttle
      extend ::ActiveSupport::Concern

      class_methods do
        attr_accessor :job_throttling

        def throttle(threshold:, period:, drop: false, key: nil)
          raise ArgumentError, "Threshold needs to be an integer > 0" if threshold.to_i < 1

          @job_throttling = {
            threshold: threshold,
            period: period,
            drop: drop,
            key: key
          }
        end

        def throttling_lock_key(job)
          lock_key("throttle", job, job_throttling)
        end
      end

      included do
        include ActiveJob::TrafficControl::Base

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
                period = self.class.job_throttling[:period]
                reenqueue(period...(period * 5), "throttling")
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
