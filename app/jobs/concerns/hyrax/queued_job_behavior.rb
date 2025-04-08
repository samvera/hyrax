# frozen_string_literal: true
module Hyrax
  # Grants the user's edit access on the provided FileSet
  module QueuedJobBehavior
    extend ActiveSupport::Concern

    included do
      queue_as Hyrax.config.ingest_queue_name
    end

    private

    def redis_queue
      Valkyrie::IndexingAdapter.find(:redis_queue)
    end

    def requeue(*args)
      self.class.set(wait_until: 5.minutes.from_now).perform_later(*args)
    end
  end
end
