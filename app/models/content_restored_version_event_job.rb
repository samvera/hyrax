class ContentRestoredVersionEventJob < EventJob
  include Hydra::AccessControlsEnforcement

  def initialize(generic_file_id, depositor_id, revision_id)
    gf = GenericFile.find(generic_file_id)
    message = "User #{link_to depositor_id, profile_path(depositor_id)} has restored a version '#{revision_id}' of #{link_to gf.title.first, generic_file_path(gf.noid)}"
    timestamp = Time.now.to_i
    depositor = User.find_by_login(depositor_id)
    # Log the event to the depositor's stream
    depositor.stream[:event].zadd(timestamp, message)
    # Log the event to the GF's steam
    gf.stream[:event].zadd(timestamp, message)
    # Fan out the event to all followers who have access
    depositor.followers.each do |user|
      user.stream[:event].zadd(timestamp, message) if user.can? :read, get_permissions_solr_response_for_doc_id(gf.pid)[1]
    end
  end
end
