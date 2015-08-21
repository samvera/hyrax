# Borrowed from:
# https://github.com/jeremy/resque-rails/blob/master/lib/resque/rails/queue.rb
module CurationConcerns
  module Resque
    class Queue
      attr_reader :default_queue_name

      def initialize(default_queue_name)
        @default_queue_name = default_queue_name
      end

      def push(job)
        push_tries = 0
        queue = job.respond_to?(:queue_name) ? job.queue_name : default_queue_name
        begin
          ::Resque.enqueue_to queue, MarshaledJob, Base64.encode64(Marshal.dump(job))
        rescue Redis::CannotConnectError
          ActiveFedora::Base.logger.error 'Redis is down!'
        rescue Redis::TimeoutError => error
          ActiveFedora::Base.logger.warn "Redis Timed out.  Trying again! #{job.inspect}"
          push_tries += 1
          # fail for good if the tries is greater than 3
          raise error if push_tries >= 3
          sleep 0.01
          retry
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
