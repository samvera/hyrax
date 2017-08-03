module Hyrax
  class RepositoryFixityCheckService
    def self.fixity_check_everything
      ::FileSet.find_each do |gf|
        Hyrax::FileSetFixityCheckService.new(gf).fixity_check
      end
    end
  end
end
