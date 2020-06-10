# frozen_string_literal: true
# A generic job for sending events to a user.
#
# @abstract
class EventJob < Hyrax::ApplicationJob
  include Rails.application.routes.url_helpers
  # For link_to
  include ActionView::Helpers
  # For link_to_profile
  include HyraxHelper

  queue_as Hyrax.config.ingest_queue_name
  attr_reader :depositor

  # @param [User] depositor the user to create the event for
  def perform(depositor)
    @depositor = depositor
    # Log the event to the depositor's profile stream
    log_user_event(depositor)
  end

  # override to provide your specific action for the event you are logging
  # @abstract
  def action
    raise(NotImplementedError, "#action should be implemented by an child class of EventJob")
  end

  # create an event with an action and a timestamp for the user
  # Use Hyrax time service!
  def event
    @event ||= Hyrax::Event.create_now(action)
  end

  # log the event to the users event stream
  def log_user_event(depositor)
    depositor.log_event(event)
  end
end
