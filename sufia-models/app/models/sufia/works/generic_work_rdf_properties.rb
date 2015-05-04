module Sufia::Works
  module GenericWorkRdfProperties
    extend ActiveSupport::Concern
    included do
      include Sufia::GenericFile::Metadata
    end
  end
end
