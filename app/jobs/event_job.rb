# A generic job for sending events to a user.
#
# This class does not implement a usable action, so it must be implemented in a child class
#
class EventJob < ActiveJob::Base
  include Rails.application.routes.url_helpers
  include ActionView::Helpers
  include ActionView::Helpers::DateHelper
  include Hydra::AccessControlsEnforcement
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
  def event
    @event ||= Hyrax::Event.create(action, Time.current.to_i)
  end

  # log the event to the users event stream
  def log_user_event(depositor)
    depositor.log_event(event)
  end
end
