require 'wings/hydra/pcdm/models/concerns/object_valkyrie_behavior'

module Wings
  module Works
    module WorkValkyrieBehavior
      extend ActiveSupport::Concern

      included do
        include Wings::Pcdm::ObjectValkyrieBehavior
      end

      # @return [Boolean] whether this instance is a Hydra::Works Collection.
      def collection?
        false
      end

      # @return [Boolean] whether this instance is a Hydra::Works Generic Work.
      def work?
        true
      end

      # @return [Boolean] whether this instance is a Hydra::Works::FileSet.
      def file_set?
        false
      end

      # @param valkyrie [Boolean] Should the returned ids be for Valkyrie or AF objects?
      # @return [Enumerable<PCDM::Object>] The works this work is contains
      def child_works(valkyrie: false)
        af_works = child_objects(valkyrie: false).select(&:work?)
        return af_works unless valkyrie
        af_works.map(&:valkyrie_resource)
      end
      alias works child_works

      # TODO: Add translated methods
    end
  end
end
