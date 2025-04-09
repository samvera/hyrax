# frozen_string_literal: true
module Hyrax
  class QueuedIndexingJob < ApplicationJob
    include QueuedJobBehavior

    def perform(size: 200)
      redis_queue.index_queue(size: size)
      requeue(size: size)
    end
  end
end
