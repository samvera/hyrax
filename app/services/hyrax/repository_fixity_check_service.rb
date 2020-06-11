# frozen_string_literal: true
module Hyrax
  class RepositoryFixityCheckService
    # This is a service that folks can use in their own rake tasks,
    # etc. It is not otherwise called or relied upon in Hyrax.
    # @see https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide#fixity-checking
    def self.fixity_check_everything
      ::FileSet.find_each do |file_set|
        Hyrax::FileSetFixityCheckService.new(file_set).fixity_check
      end
    end
  end
end
