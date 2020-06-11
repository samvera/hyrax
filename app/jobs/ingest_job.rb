# frozen_string_literal: true
class IngestJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  after_perform do |job|
    # We want the lastmost Hash, if any.
    opts = job.arguments.reverse.detect { |x| x.is_a? Hash } || {}
    wrapper = job.arguments.first
    ContentNewVersionEventJob.perform_later(wrapper.file_set, wrapper.user) if opts[:notification]
  end

  # @param [JobIoWrapper] wrapper
  # @param [Boolean] notification send the user a notification, used in after_perform callback
  # @see 'config/initializers/hyrax_callbacks.rb'
  # rubocop:disable Lint/UnusedMethodArgument
  def perform(wrapper, notification: false)
    wrapper.ingest_file
  end
end
