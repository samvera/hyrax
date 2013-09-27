module Hydra
  module AccessControls
    module Permissions
      extend ActiveSupport::Concern
      include Hydra::ModelMixins::RightsMetadata
      include Hydra::AccessControls::Visibility

      included do
        has_metadata "rightsMetadata", type: Hydra::Datastream::RightsMetadata
      end
    end
  end
end
