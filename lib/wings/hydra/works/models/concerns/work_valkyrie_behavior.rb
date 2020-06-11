# frozen_string_literal: true
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
      alias member_works child_works

      # @param valkyrie [Boolean] Should the returned ids be for Valkyrie or AF objects?
      # @return [Enumerable<String> | Enumerable<Valkerie::ID] The ids of the works this work contains
      def child_work_ids(valkyrie: false)
        child_works(valkyrie: valkyrie).map(&:id)
      end
      alias work_ids child_work_ids

      # @param valkyrie [Boolean] Should the returned resources be Valkyrie or AF objects?
      # @return [Enumerable<Hydra::Works::FileSet>] The file sets this work contains
      def child_file_sets(valkyrie: false)
        child_objects(valkyrie: valkyrie).select(&:file_set?)
      end
      alias file_sets child_file_sets

      # @param valkyrie [Boolean] Should the returned ids be for Valkyrie or AF objects?
      # @return [Enumerable<String> | Enumerable<Valkerie::ID] The ids of the file sets this work contains
      def child_file_set_ids(valkyrie: false)
        child_file_sets(valkyrie: valkyrie).map(&:id)
      end
      alias file_set_ids child_file_set_ids

      # TODO: Add translated methods
    end
  end
end
