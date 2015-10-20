# A generic job for sending events to a user and their followers.
#
# This class does not implement a usable action, so it must be implemented in a child class
#
# @attr [String] depositor_id  the user the event is specified for
#
class EventJob < ActiveJob::Base
  include Rails.application.routes.url_helpers
  include ActionView::Helpers
  include ActionView::Helpers::DateHelper
  include Hydra::AccessControlsEnforcement
  include SufiaHelper

  queue_as :event

  attr_accessor :depositor_id

  # @param depositor_id the id of the user to create the event for
  def perform(depositor_id)
    @depositor_id = depositor_id

    # Log the event to the depositor's profile stream
    log_user_event

    # Fan out the event to all followers who have access
    log_to_followers
  end

  # override to provide your specific action for the event you are logging
  # @abstract
  def action
    raise(NotImplementedError, "#action should be implemented by an child class of EventJob")
  end

  # create an event with an action and a timestamp for the user
  def event
    @event ||= depositor.create_event(action, Time.now.to_i)
  end

  # the user that will be the subject of the event
  def depositor
    @depositor ||= User.find_by_user_key(depositor_id)
  end

  # log the event to the users event stream
  def log_user_event
    depositor.log_event(event)
  end

  # log the event to the users followers
  def log_to_followers
    depositor.followers.each do |follower|
      follower.log_event(event)
    end
  end
end
