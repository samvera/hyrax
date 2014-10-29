class ContentDepositorChangeEventJob < EventJob

  def queue_name
    :proxy_deposit
  end

  attr_accessor :pid, :login, :reset

  # @param [String] pid identifier of the file to be transfered
  # @param [String] login the user key of the user the file is being transfered to.
  # @param [Boolean] reset (false) should the access controls be reset. This means revoking edit access from the depositor
  def initialize(pid, login, reset=false)
    self.pid = pid
    self.login = login
    self.reset = reset
  end

  def run
    # TODO: This should be in its own job, not this event job
    file = ::GenericFile.find(pid)
    file.proxy_depositor = file.depositor
    file.rightsMetadata.clear_permissions! if reset
    file.apply_depositor_metadata(login)
    file.save!

    action = "User #{link_to_profile file.proxy_depositor} has transferred #{link_to file.title.first, Sufia::Engine.routes.url_helpers.generic_file_path(file.noid)} to User #{link_to_profile login}"
    timestamp = Time.now.to_i
    depositor = ::User.find_by_user_key(file.depositor)
    proxy_depositor = ::User.find_by_user_key(file.proxy_depositor)
    # Create the event
    event = proxy_depositor.create_event(action, timestamp)
    # Log the event to the GF's stream
    file.log_event(event)

    #log the event to the depositor
    log_depositor_event(event, depositor, file)

    #log the event to the proxy_depositor
    log_depositor_event(event, proxy_depositor, file)
  end

  def log_depositor_event(event, depositor, gf)
    # Log the event to the depositor's profile stream
    depositor.log_profile_event(event)
    # Fan out the event to all followers who have access
    depositor.followers.select { |user| user.can? :read, gf }.each do |follower|
      follower.log_event(event)
    end
  end
end
