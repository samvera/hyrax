module Worthwhile
  # Inherit from the host app's ApplicationController
  # This will configure e.g. the layout used by the host
  class ApplicationController < ::ApplicationController
    include Worthwhile::ApplicationControllerBehavior
  end
end
