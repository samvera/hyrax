# Copied from Curate
module CurationConcerns
  module WithFileSets
    extend ActiveSupport::Concern

    included do
      # The file_sets association and its accessor methods comes from Hydra::Works::AggregatesFileSets
      before_destroy :before_destroy_cleanup_file_sets
    end

    # Stopgap unil ActiveFedora ContainerAssociation includes an *_ids accessor.
    # At the moment, this is no more efficient than calling file_sets, but hopefully that will change in the future.
    def file_set_ids
      file_sets.map(&:id)
    end

    def before_destroy_cleanup_file_sets
      file_sets.each(&:destroy)
    end

    def copy_visibility_to_files
      file_sets.each do |fs|
        fs.visibility = visibility
        fs.save!
      end
    end
  end
end
