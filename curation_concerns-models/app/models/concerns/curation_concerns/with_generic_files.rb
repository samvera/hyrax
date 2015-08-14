# Copied from Curate
module CurationConcerns
  module WithGenericFiles
    extend ActiveSupport::Concern

    included do
      # The generic_files association and its accessor methods comes from Hydra::Works::AggregatesGenericFiles
      before_destroy :before_destroy_cleanup_generic_files
    end

    # Stopgap unil ActiveFedora ContainerAssociation includes an *_ids accessor.
    # At the moment, this is no more efficient than calling generic_files, but hopefully that will change in the future.
    def generic_file_ids
      generic_files.map(&:id)
    end

    def before_destroy_cleanup_generic_files
      generic_files.each(&:destroy)
    end

    def copy_visibility_to_files
      generic_files.each do |gf|
        gf.visibility = visibility
        gf.save!
      end
    end
  end
end
