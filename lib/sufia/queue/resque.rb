require 'active_support/core_ext/marshal'

# Borrowed from:
# https://github.com/jeremy/resque-rails/blob/master/lib/resque/rails/queue.rb
module Sufia
  module Resque
    class Queue
      attr_reader :default_queue_name

      def initialize(default_queue_name)
        @default_queue_name = default_queue_name
      end

      def push(job)
        queue = job.respond_to?(:queue_name) ? job.queue_name : default_queue_name
        begin
          ::Resque.enqueue_to queue, MarshaledJob, Base64.encode64(Marshal.dump(job))
        rescue Redis::CannotConnectError
          logger.error "Redis is down!"
        end
      end
    end

    class MarshaledJob
      def self.perform(marshaled_job)
        Marshal.load(Base64.decode64(marshaled_job)).run
      end
    end
  end
end
