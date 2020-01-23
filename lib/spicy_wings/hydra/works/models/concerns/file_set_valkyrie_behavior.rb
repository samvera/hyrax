require 'spicy_wings/hydra/pcdm/models/concerns/object_valkyrie_behavior'

module SpicyWings
  module Works
    module FileSetValkyrieBehavior
      extend ActiveSupport::Concern

      included do
        include SpicyWings::Pcdm::ObjectValkyrieBehavior
      end

      # @return [Boolean] whether this instance is a Hydra::Works Collection.
      def collection?
        false
      end

      # @return [Boolean] whether this instance is a Hydra::Works Generic Work.
      def work?
        false
      end

      # @return [Boolean] whether this instance is a Hydra::Works::FileSet.
      def file_set?
        true
      end

      # TODO: Add translated methods
    end
  end
end
