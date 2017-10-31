module Hyrax
  module FileSet
    module BelongsToWorks
      extend ActiveSupport::Concern

      # included do
      #   before_destroy :remove_representative_relationship
      # end

      # Objects that call this FileSet a member
      def parents
        query_service.parents(resource: self)
      end
      deprecation_deprecate parents: 'use query_service#parents() instead.'

      # Returns the first parent object
      # This is a hack to handle things like FileSets inheriting access controls from their parent.  (see Hyrax::ParentContainer in app/controllers/concerns/hyrax/parent_container.rb)
      def parent
        parents.first
      end

      # Returns the id of first parent object
      # This is a hack to handle things like FileSets inheriting access controls from their parent.  (see Hyrax::ParentContainer in app/controllers/concerns/hyrax/parent_container.rb)
      delegate :id, to: :parent, prefix: true

      # If any parent objects are pointing at this object as their
      # representative, remove that pointer.
      # def remove_representative_relationship
      #   parent_objects = parents
      #   return if parent_objects.empty?
      #   parent_objects.each do |work|
      #     work.update(representative_id: nil) if work.representative_id == id
      #   end
      # end
    end
  end
end
\
