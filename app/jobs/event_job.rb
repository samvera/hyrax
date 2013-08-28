class EventJob
  include Rails.application.routes.url_helpers
  include ActionView::Helpers
  include ActionView::Helpers::DateHelper
  include Hydra::AccessControlsEnforcement
  include SufiaHelper

  def queue_name
    :event
  end

  attr_accessor :generic_file_id, :depositor_id

  def initialize(generic_file_id, depositor_id)
    self.generic_file_id = generic_file_id
    self.depositor_id = depositor_id
  end

end
