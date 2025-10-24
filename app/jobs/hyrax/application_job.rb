# frozen_string_literal: true
module Hyrax
  # A common base class for all Hyrax jobs.
  # This allows downstream applications to manipulate all the hyrax jobs by
  # including modules on this class.
  class ApplicationJob < ::ApplicationJob
    before_enqueue do |job|
      job.arguments.map! do |arg|
        case arg
        when Valkyrie::Resource
          Hyrax::ValkyrieGlobalIdProxy.new(resource: arg)
        else
          arg
        end
      end
    end

    def perform_later(*args)
      if provider_job_id.present? && Flipflop.deterministic_jobs?
        perform_now(*args)
      else
        super
      end
    end
  end
end
