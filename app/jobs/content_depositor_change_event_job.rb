# frozen_string_literal: true
# Log work depositor change to activity streams
#
# This class simply logs the transfer, pulling data from the object that was
# just transferred. It does not perform the transfer.
class ContentDepositorChangeEventJob < ContentEventJob
  include Rails.application.routes.url_helpers
  include ActionDispatch::Routing::PolymorphicRoutes

  # @param [ActiveFedora::Base] work the work that's been transfered
  def perform(work)
    # these get set to repo_object and depositor
    super(work, new_owner(work))
  end

  def action
    "User #{link_to_profile repo_object.proxy_depositor} has transferred #{link_to_work repo_object.title.first} to user #{link_to_profile depositor}"
  end

  def link_to_work(text)
    link_to text, polymorphic_path(repo_object)
  end

  # Log the event to the work's stream
  def log_work_event(work)
    work.log_event(event)
  end
  alias log_file_set_event log_work_event

  # overriding default to log the event to the depositor instead of their profile
  # and to log the event for both users
  def log_user_event(depositor)
    previous_owner.log_profile_event(event)
    depositor.log_event(event)
  end

  private def previous_owner
    ::User.find_by_user_key(repo_object.proxy_depositor)
  end

  # used for @depositor
  private def new_owner(work)
    ::User.find_by_user_key(work.depositor)
  end
end
