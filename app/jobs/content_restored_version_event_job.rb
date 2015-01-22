class ContentRestoredVersionEventJob < EventJob
  attr_accessor :revision_id

  def initialize(generic_file_id, depositor_id, revision_id)
    self.generic_file_id = generic_file_id
    self.depositor_id = depositor_id
    self.revision_id = revision_id
  end

  def run
    gf = GenericFile.find(generic_file_id)
    action = "User #{link_to_profile depositor_id} has restored a version '#{revision_id}' of #{link_to gf.title.first, Sufia::Engine.routes.url_helpers.generic_file_path(gf)}"
    timestamp = Time.now.to_i
    depositor = User.find_by_user_key(depositor_id)
    # Create the event
    event = depositor.create_event(action, timestamp)
    # Log the event to the depositor's profile stream
    depositor.log_profile_event(event)
    # Log the event to the GF's stream
    gf.log_event(event)
    # Fan out the event to all followers who have access
    depositor.followers.select { |user| user.can? :read, gf }.each do |follower|
      follower.log_event(event)
    end
  end
end
