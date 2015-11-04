module Sufia::Works
  module GenericWorkRdfProperties
    extend ActiveSupport::Concern
    included do
      include Sufia::FileSet::Metadata
    end
  end
end
