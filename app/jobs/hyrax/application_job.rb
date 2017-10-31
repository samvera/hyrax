module Hyrax
  # A common base class for all Hyrax jobs.
  # This allows downstream applications to manipulate all the hyrax jobs by
  # including modules on this class.
  class ApplicationJob < ActiveJob::Base
    private

      def persister
        Valkyrie::MetadataAdapter.find(:indexing_persister).persister
      end
  end
end
