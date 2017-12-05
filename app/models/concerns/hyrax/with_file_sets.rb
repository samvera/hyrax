module Hyrax
  module WithFileSets
    extend ActiveSupport::Concern

    def file_sets
      Hyrax::Queries.find_members(resource: self, model: ::FileSet)
    end

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
