module Worthwhile
  module CurationConcern
    class GenericFileActor < Sufia::GenericFile::Actor

      def create_metadata(batch_id)
        if batch_id
          generic_file.visibility = load_parent(batch_id).visibility
        end
        super
      end

      def load_parent(batch_id)
        @parent ||= GenericWork.find(batch_id)
      end
    end
  end
end
