module Sufia
  module GenericFile
    module Featured
      extend ActiveSupport::Concern

      def featured?
        FeaturedWork.where(generic_file_id: id).exists?
      end
    end
  end
end
