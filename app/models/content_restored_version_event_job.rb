class ContentRestoredVersionEventJob < EventJob
  def initialize(generic_file_id, depositor_id, revision_id)
    gf = GenericFile.find(generic_file_id)
    action = "User #{link_to depositor_id, profile_path(depositor_id)} has restored a version '#{revision_id}' of #{link_to gf.title.first, generic_file_path(gf.noid)}"
    timestamp = Time.now.to_i
    depositor = User.find_by_login(depositor_id)
    # Create the event
    event = depositor.create_event(action, timestamp)
    # Log the event to the depositor's profile stream
    depositor.log_profile_event(event)
    # Log the event to the GF's stream
    gf.log_event(event)
    # Fan out the event to all followers who have access
    depositor.followers.select { |user| user.can? :read, get_permissions_solr_response_for_doc_id(gf.pid)[1] }.each do |follower|
      follower.log_event(event)
    end
  end
end
