# Log work depositor change to activity streams
#
# @attr [Boolean] reset (false) should the access controls be reset. This means revoking edit access from the depositor
class ContentDepositorChangeEventJob < ContentEventJob
  queue_as :proxy_deposit

  attr_accessor :reset

  # @param [GenericWork] generic_work the generic work to be transfered
  # @param [User] user the user the generic work is being transfered to.
  # @param [TrueClass,FalseClass] reset (false) if true, reset the access controls. This revokes edit access from the depositor
  def perform(generic_work, user, reset = false)
    @reset = reset
    super(generic_work, user)
  end

  def action
    "User #{link_to_profile work.proxy_depositor} has transferred #{link_to work.title.first, Rails.application.routes.url_helpers.curation_concerns_generic_work_path(work)} to user #{link_to_profile depositor}"
  end

  # Log the event to the GenericWork's stream
  def log_work_event(work)
    work.log_event(event)
  end
  alias log_file_set_event log_work_event

  def work
    @work ||= Sufia::ChangeContentDepositorService.call(repo_object, depositor, reset)
  end

  # overriding default to log the event to the depositor instead of their profile
  def log_user_event(depositor)
    # log the event to the proxy depositor's profile
    proxy_depositor.log_profile_event(event)
    depositor.log_event(event)
  end

  def proxy_depositor
    @proxy_depositor ||= ::User.find_by_user_key(work.proxy_depositor)
  end

  # override to check file permissions before logging to followers
  def log_to_followers(depositor)
    depositor.followers.select { |user| user.can?(:read, work) }.each do |follower|
      follower.log_event(event)
    end
  end
end
