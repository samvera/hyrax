# frozen_string_literal: true
module Hyrax
  # A common base class for all Hyrax jobs.
  # This allows downstream applications to manipulate all the hyrax jobs by
  # including modules on this class.
  class ApplicationJob < ::ApplicationJob
    before_enqueue do |job|
      job.arguments.map! do |arg|
        arg.is_a?(Valkyrie::Resource) ? Hyrax::ActiveJobProxy.new(resource: arg) : arg
      end
    end
  end
end
