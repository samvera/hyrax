class EventJob < ActiveJob::Base
  include Rails.application.routes.url_helpers
  include ActionView::Helpers
  include ActionView::Helpers::DateHelper
  include Hydra::AccessControlsEnforcement
  include SufiaHelper

  queue_as :event
end
