module Hyrax
  module WithFileSets
    extend ActiveSupport::Concern

    def file_sets
      Hyrax::Queries.find_members(resource: self, model: ::FileSet)
    end

    def copy_visibility_to_files
      file_sets.each do |fs|
        fs.visibility = visibility
        fs.save!
      end
    end
  end
end
