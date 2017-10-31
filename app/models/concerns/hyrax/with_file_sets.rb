module Hyrax
  module WithFileSets
    extend ActiveSupport::Concern
    def copy_visibility_to_files
      file_sets.each do |fs|
        fs.visibility = visibility
        persister.save(resource: fs)
      end
    end

    private

      def persister
        Valkyrie::MetadataAdapter.find(:indexing_persister).persister
      end
  end
end
