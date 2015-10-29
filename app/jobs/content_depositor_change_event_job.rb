class ContentDepositorChangeEventJob < EventJob
  def queue_name
    :proxy_deposit
  end

  attr_accessor :id, :login, :reset

  # @param [String] id identifier of the generic work to be transfered
  # @param [String] login the user key of the user the generic work is being transfered to.
  # @param [Boolean] reset (false) should the access controls be reset. This means revoking edit access from the depositor
  def initialize(id, login, reset = false)
    self.id = id
    self.login = login
    self.reset = reset
  end

  def run
    # TODO: This should be in its own job, not this event job
    work = ::GenericWork.find(id)
    work.proxy_depositor = work.depositor
    work.clear_permissions! if reset
    work.apply_depositor_metadata(login)
    work.file_sets.each do |f|
      f.apply_depositor_metadata(login)
      f.save!
    end
    work.save!

    action = "User #{link_to_profile work.proxy_depositor} has transferred #{link_to work.title.first, Sufia::Engine.routes.url_helpers.generic_work_path(work)} to user #{link_to_profile login}"
    timestamp = Time.now.to_i
    depositor = ::User.find_by_user_key(work.depositor)
    proxy_depositor = ::User.find_by_user_key(work.proxy_depositor)
    # Create the event
    event = proxy_depositor.create_event(action, timestamp)
    # Log the event to the FS's stream
    work.log_event(event)
    # log the event to the proxy depositor's profile
    proxy_depositor.log_profile_event(event)
    # log the event to the depositor's dashboard
    depositor.log_event(event)
    # Fan out the event to the depositor's followers who have access
    depositor.followers.select { |user| user.can? :read, work }.each do |follower|
      follower.log_event(event)
    end
  end
end
