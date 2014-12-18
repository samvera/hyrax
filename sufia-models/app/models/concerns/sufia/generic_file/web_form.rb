module Sufia
  module GenericFile
    module WebForm
      extend ActiveSupport::Concern
      include Sufia::GenericFile::AccessibleAttributes
      included do
        attr_accessible :resource_type, :title, :creator, :contributor, :description, :tag,
          :rights, :publisher, :date_created, :subject, :language, :identifier, :based_near,
          :related_url, :part_of, :permissions_attributes
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
