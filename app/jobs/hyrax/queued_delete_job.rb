# frozen_string_literal: true
module Hyrax
  class QueuedDeleteJob < ApplicationJob
    include QueuedJobBehavior

    def perform(size: 200)
      redis_queue.delete_queue(size: size)
      requeue(size: size)
    end
  end
end
