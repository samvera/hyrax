module Hyrax
  module FileSet
    module BelongsToWorks
      extend ActiveSupport::Concern

      included do
        before_destroy :remove_representative_relationship
      end

      def parents
        in_works
      end

      # Returns the first parent object
      # This is a hack to handle things like FileSets inheriting access controls from their parent.  (see Hyrax::ParentContainer in app/controllers/concerns/curation_concers/parent_container.rb)
      def parent
        parents.first
      end

      # Returns the id of first parent object
      # This is a hack to handle things like FileSets inheriting access controls from their parent.  (see Hyrax::ParentContainer in app/controllers/concerns/curation_concers/parent_container.rb)
      delegate :id, to: :parent, prefix: true

      # Files with sibling relationships
      # Returns all FileSets aggregated by any of the parent objects that
      # aggregate the current object
      def related_files
        parent_objects = parents
        return [] if parent_objects.empty?
        parent_objects.flat_map do |work|
          work.file_sets.select do |file_set|
            file_set.id != id
          end
        end
      end

      # If any parent objects are pointing at this object as their
      # representative, remove that pointer.
      def remove_representative_relationship
        parent_objects = parents
        return if parent_objects.empty?
        parent_objects.each do |work|
          work.update(representative_id: nil) if work.representative_id == id
        end
      end
    end
  end
end
\
