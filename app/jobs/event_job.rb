class EventJob
  include Rails.application.routes.url_helpers
  include ActionView::Helpers
  include ActionView::Helpers::DateHelper
  include Hydra::AccessControlsEnforcement
  include SufiaHelper

  def queue_name
    :event
  end

  attr_accessor :id, :depositor_id

  def initialize(id, depositor_id)
    self.id = id
    self.depositor_id = depositor_id
  end

end
