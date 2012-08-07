class ContentNewVersionEventJob < EventJob
  def initialize(generic_file_id, depositor_id)
    gf = GenericFile.find(generic_file_id)
    message = "User #{link_to depositor_id, profile_path(depositor_id)} has added a new version of #{link_to gf.title.first, generic_file_path(gf.noid)}"
    timestamp = Time.now.to_i
    depositor = User.find_by_login(depositor_id)
    # Log the event to the depositor's profile stream
    depositor.stream[:event][:profile].zadd(timestamp, message)
    # Log the event to the GF's stream
    gf.stream[:event].zadd(timestamp, message)
    # Fan out the event to all followers who have access
    depositor.followers.select { |user| user.can? :read, get_permissions_solr_response_for_doc_id(gf.pid)[1] }.each do |follower|
      follower.stream[:event].zadd(timestamp, message)
    end
  end
end
