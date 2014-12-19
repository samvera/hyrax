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

    end
  end
end
