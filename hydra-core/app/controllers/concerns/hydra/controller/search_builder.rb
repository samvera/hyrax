module Hydra::Controller::SearchBuilder
  extend ActiveSupport::Concern

  included do
    Deprecation.warn Hydra::Controller::SearchBuilder, "Hydra::Controller::SearchBuilder no longer does anything.  It will be removed in Hydra version 10.  The code that used to be in this module was moved to Blacklight::AccessControls::Catalog in the blacklight-access_controls gem."
  end

end
