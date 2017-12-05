module Hyrax
  module LinkedDataResources
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :BaseResource
      autoload :GeonamesResource
    end
  end
end
