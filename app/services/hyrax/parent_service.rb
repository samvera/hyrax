module Hyrax
  class ParentService
    # @param [String] id - the id of a child FileSet
    # @return [Valkyrie::Resource] the parent object
    def self.parent_for(id)
      ids = ordered_by_ids(id)
      find_resource(ordered_by_ids(id).first) if ids.present?
    end

    def self.ordered_by_ids(id)
      if id.present?
        ActiveFedora::SolrService.query("{!join from=proxy_in_ssi to=id}ordered_targets_ssim:#{id}")
                                 .map { |x| x["id"] }
      else
        []
      end
    end

    private

      def find_resource(id)
        query_service.find_by(id: Valkyrie::ID.new(id.to_s))
      end

      def query_service
        Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      end
  end
end
