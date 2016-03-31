# A specific job to log a file new version to a user's activity stream
class ContentNewVersionEventJob < ContentEventJob
  def action
    @action ||= "User #{link_to_profile depositor} has added a new version of #{link_to file_set.title.first, Rails.application.routes.url_helpers.curation_concerns_file_set_path(file_set)}"
  end
end
