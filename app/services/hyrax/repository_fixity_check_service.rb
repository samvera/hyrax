# frozen_string_literal: true

module Hyrax
  class RepositoryFixityCheckService
    # TODO: this never seems to be used. Remove?
    def self.fixity_check_everything
      ::FileSet.find_each do |gf|
        Hyrax::FileSetFixityCheckService.new(gf).fixity_check
      end
    end
  end
end
