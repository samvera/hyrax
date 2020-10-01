# frozen_string_literal: true

module Hyrax
  ##
  # Indexes Hyrax::Work objects
  class ValkyrieWorkIndexer < Hyrax::ValkyrieIndexer
    include Hyrax::ResourceIndexer
    include Hyrax::PermissionIndexer
    include Hyrax::VisibilityIndexer
    include Hyrax::Indexer(:core_metadata)

    def to_solr # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      super.tap do |solr_doc|
        solr_doc['generic_type_sim'] = ['Work']
        solr_doc['admin_set_id_ssim'] = [resource.admin_set_id]
        solr_doc['member_of_collection_ids_ssim'] = resource.member_of_collection_ids
        solr_doc['member_ids_ssim'] = resource.member_ids

        # attributes from Hyrax::Work not defined by Hyrax::Schema includes
        # solr_doc['on_behalf_of'] = ''
        # solr_doc['proxy_depositor'] = ''
        # solr_doc['state'] = ''

        # This enables us to return a Work when we have a FileSet that matches
        # the search query.  While at the same time allowing us not to return Collections
        # when a work in the collection matches the query.
        # solr_doc['file_set_ids_ssim'] = solr_doc['member_ids_ssim'] # TODO: Doesn't this return child works too?
      end
    end
  end
end
