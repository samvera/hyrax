# A specific job to log a file deposit to a user's activity stream
class ContentDepositEventJob < ContentEventJob
  def perform(file_set, depositor)
    @file_set = file_set
    @depositor = depositor
    super
  end

  def action
    "User #{link_to_profile @depositor} has deposited #{link_to @file_set.title.first, Rails.application.routes.url_helpers.curation_concerns_file_set_path(@file_set)}"
  end
end
