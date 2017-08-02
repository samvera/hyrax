module Hyrax
  module WithFileSets
    extend ActiveSupport::Concern
    def copy_visibility_to_files
      file_sets.each do |fs|
        fs.visibility = visibility
        fs.save!
      end
    end
  end
end
