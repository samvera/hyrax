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

      # @param valkyrie [Boolean] Should the returned resources be Valkyrie or AF objects?
      # @return [Enumerable<Hydra::Works::Work>] The works this work contains
      def child_works(valkyrie: false)
        child_objects(valkyrie: valkyrie).select(&:work?)
      end
      alias works child_works

      # @param valkyrie [Boolean] Should the returned ids be for Valkyrie or AF objects?
      # @return [Enumerable<String> | Enumerable<Valkerie::ID] The ids of the works this work contains
      def child_work_ids(valkyrie: false)
        child_works(valkyrie: valkyrie).map(&:id)
      end
      alias work_ids child_work_ids

      # TODO: Add translated methods
    end
  end
end
