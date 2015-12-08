# A specific job to log a file deposit change to a user's activity stream
#
# This is a bit wierd becuase the job performs the depositor transfer along with logging the job
#
# @attr [String] id identifier of the file to be transfered
# @attr [String] login the user key of the user the file is being transfered to.
# @attr [Boolean] reset (false) should the access controls be reset. This means revoking edit access from the depositor
class ContentDepositorChangeEventJob < ContentEventJob
  queue_as :proxy_deposit

  attr_accessor :generic_work_id, :login, :reset

  # @param [String] id identifier of the generic work to be transfered
  # @param [String] login the user key of the user the generic work is being transfered to.
  # @param [TrueClass,FalseClass] reset (false) if true, reset the access controls. This revokes edit access from the depositor
  def perform(generic_work_id, login, reset = false)
    @generic_work_id = generic_work_id
    @login = login
    @reset = reset
    super(generic_work_id, login)
  end

  # create an event with an action and a timestamp for the user
  def event
    @event ||= proxy_depositor.create_event(action, Time.now.to_i)
  end

  def action
    "User #{link_to_profile work.proxy_depositor} has transferred #{link_to work.title.first, Rails.application.routes.url_helpers.curation_concerns_generic_work_path(work)} to user #{link_to_profile login}"
  end

  # Log the event to the GenericWork's stream
  def log_work_event
    work.log_event(event)
  end
  alias_method :log_file_set_event, :log_work_event

  def work
    @work ||= Sufia::ChangeContentDepositorService.call(generic_work_id, login, reset)
  end

  # overriding default to log the event to the depositor instead of their profile
  def log_user_event
    # log the event to the proxy depositor's profile
    proxy_depositor.log_profile_event(event)
    depositor.log_event(event)
  end

  def proxy_depositor
    @proxy_depositor ||= ::User.find_by_user_key(work.proxy_depositor)
  end

  # override to check file permissions before logging to followers
  def log_to_followers
    depositor.followers.select { |user| user.can?(:read, work) }.each do |follower|
      follower.log_event(event)
    end
  end
end
