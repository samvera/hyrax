module Sufia
  module GenericFile
    module Trophies
      extend ActiveSupport::Concern
      included do
        before_destroy :cleanup_trophies
      end

      def cleanup_trophies
        Trophy.destroy_all(generic_file_id: self.noid)
      end

    end
  end
end
