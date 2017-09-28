module Hyrax
  module ControlledVocabularies
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Location
    end
  end
end
