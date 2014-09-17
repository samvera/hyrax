# Copied from Curate
module CurationConcern
  module WithGenericFiles
    extend ActiveSupport::Concern

    included do
      has_many :generic_files, property: :is_part_of, class_name: "Worthwhile::GenericFile"
      before_destroy :before_destroy_cleanup_generic_files
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
