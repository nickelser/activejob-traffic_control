# frozen_string_literal: true

module ActiveJob
  module TrafficControl
    module Concurrency
      extend ::ActiveSupport::Concern

      class_methods do
        attr_accessor :job_concurrency

        def concurrency(threshold, drop: true, key: nil, wait_timeout: 0.1, stale_timeout: 60 * 10)
          raise ArgumentError, "Concurrent jobs needs to be an integer > 0" if threshold.to_i < 1
          @job_concurrency = {
            threshold: threshold.to_i,
            drop: drop,
            wait_timeout: wait_timeout.to_f,
            stale_timeout: stale_timeout.to_f,
            key: key
          }
        end

        def concurrency_key
          if job_concurrency
            @concurrency_key ||= begin
              if job_concurrency[:key].present?
                job_concurrency[:key]
              else
                "traffic_control:concurrency:#{cleaned_name}"
              end
            end
          end
        end
      end

      included do
        include ActiveJob::TrafficControl::Base

        around_perform do |_, block|
          if self.class.job_concurrency.present?
            lock_options = {
              resources: self.class.job_concurrency[:threshold],
              acquisition_lock: self.class.job_concurrency[:wait_timeout],
              stale_lock_expiration: self.class.job_concurrency[:stale_timeout]
            }

            with_lock_client(self.class.concurrency_key, lock_options) do |client|
              locked = client.lock do
                block.call
                true
              end

              unless locked
                if self.class.job_concurrency[:drop]
                  drop("concurrency")
                else
                  reenqueue(CONCURRENCY_REENQUEUE_DELAY, "concurrency")
                end
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
