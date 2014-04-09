module Sufia
  module GenericFile
    module Featured
      extend ActiveSupport::Concern


      def featured?
        FeaturedWork.where(generic_file_id: noid).exists?
      end

    end
  end
end

