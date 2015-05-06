module Sufia::Works
  module CurationConcern
    module Work
      extend ActiveSupport::Concern
      include WithGenericFiles
      include HumanReadableType
      include Sufia::Noid
      include Sufia::ModelMethods
      include Hydra::Collections::Collectible
      include Solrizer::Common
      include Sufia::GenericFile::Permissions
    end
  end
end
