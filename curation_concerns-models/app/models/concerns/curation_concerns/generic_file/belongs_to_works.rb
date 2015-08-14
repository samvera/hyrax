module CurationConcerns
  module GenericFile
    module BelongsToWorks
      extend ActiveSupport::Concern

      included do
        before_destroy :remove_representative_relationship
      end

      def generic_works
        parent_objects # parent_objects is provided by Hydra::PCDM::ObjectBehavior
      end

      def generic_work_ids
        generic_works.map(&:id)
      end

      # Returns the first parent object
      # This is a hack to handle things like GenericFiles inheriting access controls from their parent.  (see CurationConcerns::ParentContainer in app/controllers/concerns/curation_concers/parent_container.rb)
      def parent
        parent_objects.first
      end

      # Returns the id of first parent object
      # This is a hack to handle things like GenericFiles inheriting access controls from their parent.  (see CurationConcerns::ParentContainer in app/controllers/concerns/curation_concers/parent_container.rb)
      delegate :id, to: :parent, prefix: true

      # Files with sibling relationships
      # Returns all GenericFiles aggregated by any of the GenericWorks that aggregate the current object
      def related_files
        generic_works = self.generic_works
        return [] if generic_works.empty?
        generic_works.flat_map { |work| work.generic_files.select { |generic_file| generic_file.id != id } }
      end

      # If any parent works are pointing at this object as their representative, remove that pointer.
      def remove_representative_relationship
        generic_works = self.generic_works
        return if generic_works.empty?
        generic_works.each do |work|
          if work.representative == id
            work.representative = nil
            work.save
          end
        end
      end
    end
  end
end
