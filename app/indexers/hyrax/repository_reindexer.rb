require 'active_fedora/base'
require 'active_fedora/version'

module Hyrax
  module RepositoryReindexer
    extend ActiveSupport::Concern

    module ClassMethods
      # overrides https://github.com/samvera/active_fedora/blob/master/lib/active_fedora/indexing.rb#L95-L125
      # see implementation details in adapters/nesting_index_adapter.rb#each_perservation_document_id_and_parent_ids
      def reindex_everything(*)
        Samvera::NestingIndexer.reindex_all!(extent: Hyrax::Adapters::NestingIndexAdapter::FULL_REINDEX)
      end
    end
  end
end

ActiveFedora::Base.module_eval { include Hyrax::RepositoryReindexer }
