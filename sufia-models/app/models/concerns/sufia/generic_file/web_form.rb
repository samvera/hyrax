module Sufia
  module GenericFile
    module WebForm
      extend ActiveSupport::Concern
      include Sufia::GenericFile::AccessibleAttributes
      included do
        before_save :remove_blank_assertions
        attr_accessible *(terms_for_display + [:part_of, :permissions_attributes])
      end

      def remove_blank_assertions
        terms_for_editing.each do |key|
          if self[key] == ['']
            self[key] = []
            changed_attributes.delete(key) if attribute_was(key) == []
          end
        end
      end

      # override this method if you need to initialize more complex RDF assertions (b-nodes)
      def initialize_fields
        terms_for_editing.select { |key| self[key].blank? }.each do |key|
          # if value is empty, we create an one element array to loop over for output
          if self.class.multiple?(key)
            self[key] = ['']
          else
            self[key] = ''
          end
        end
      end

      def terms_for_editing
        terms_for_display - [:date_modified, :date_uploaded, :format]
      end

      def terms_for_display
        # 'type' is the RDF.type assertion, which is not present by default, but may be
        # provided in some RDF schemas
        self.class.terms_for_display
      end

      module ClassMethods
        def terms_for_display
          [:resource_type, :title, :creator, :contributor, :description, :tag, :rights, :publisher, :date_created,
           :subject, :language, :identifier, :based_near, :related_url]
        end
      end

      def to_jq_upload
        return {
          "name" => title,
          "size" => file_size,
          "url" => "/files/#{noid}",
          "thumbnail_url" => id,
          "delete_url" => "deleteme", # generic_file_path(id: id),
          "delete_type" => "DELETE"
        }
      end

    end
  end
end
