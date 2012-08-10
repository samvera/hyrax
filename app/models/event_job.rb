class EventJob
  include Rails.application.routes.url_helpers
  include ActionView::Helpers
  include ActionView::Helpers::DateHelper
  include Hydra::AccessControlsEnforcement

  def self.queue
    :event
  end

  def self.perform(*args)
    new(*args)
  end
end
