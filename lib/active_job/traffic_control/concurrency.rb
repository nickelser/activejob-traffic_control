# frozen_string_literal: true

module ActiveJob
  module TrafficControl
    module Concurrency
      extend ::ActiveSupport::Concern

      CONCURRENCY_REENQUEUE_DELAY = ENV["RACK_ENV"] == "test" ? 1...5 : 30...(60 * 5)

      class_methods do
        def concurrency(threshold, drop: false, key: nil, wait_timeout: 0.1, stale_timeout: 60 * 10)
          raise ArgumentError, "Concurrent jobs needs to be an integer > 0" if threshold.to_i < 1

          self.job_concurrency = {
            threshold: threshold.to_i,
            drop: drop,
            wait_timeout: wait_timeout.to_f,
            stale_timeout: stale_timeout.to_f,
            key: key
          }
        end

        def concurrency_lock_key(job)
          lock_key("concurrency", job, job_concurrency)
        end
      end

      included do
        include ActiveJob::TrafficControl::Base

        class_attribute :job_concurrency, instance_accessor: false

        around_perform do |job, block|
          if self.class.job_concurrency.present?
            lock_options = {
              resources: self.class.job_concurrency[:threshold],
              acquisition_lock: self.class.job_concurrency[:wait_timeout],
              stale_lock_expiration: self.class.job_concurrency[:stale_timeout]
            }

            with_lock_client(self.class.concurrency_lock_key(job), lock_options) do |client|
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
