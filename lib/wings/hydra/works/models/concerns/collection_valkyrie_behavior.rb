# frozen_string_literal: true
require 'wings/hydra/pcdm/models/concerns/collection_valkyrie_behavior'

module Wings
  module Works
    module CollectionValkyrieBehavior
      extend ActiveSupport::Concern

      included do
        include Wings::Pcdm::CollectionValkyrieBehavior
      end

      # @return [Boolean] whether this instance is a Hydra::Works Collection.
      def collection?
        true
      end

      # @return [Boolean] whether this instance is a Hydra::Works Generic Work.
      def work?
        false
      end

      # @return [Boolean] whether this instance is a Hydra::Works::FileSet.
      def file_set?
        false
      end

      # TODO: Add translated methods
    end
  end
end
