module Hyrax
  module WithFileSets
    extend ActiveSupport::Concern

    included do
      # The file_sets association and its accessor methods comes from Hydra::Works::AggregatesFileSets
      before_destroy :cleanup_file_sets
    end

    def cleanup_file_sets
      # Destroy the list source first.  This prevents each file_set from attemping to
      # remove itself individually from the work. If hundreds of files are attached,
      # this would take too long.

      # Get list of member file_sets from Solr
      fs = file_sets
      list_source.destroy
      # Remove Work from Solr after it was removed from Fedora
      ActiveFedora::SolrService.delete(id)
      fs.each(&:destroy)
    end

    def copy_visibility_to_files
      file_sets.each do |fs|
        fs.visibility = visibility
        fs.save!
      end
    end
  end
end
