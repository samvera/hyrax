module Sufia::Works
  module CurationConcern
    module Work
      extend ActiveSupport::Concern
      include WithFileSets
      include HumanReadableType
      include Sufia::Noid
      include Sufia::ModelMethods
      include Solrizer::Common
      include Sufia::FileSet::Permissions
      include Indexing
    end
  end
end
