module CurationConcerns
  class ParentService
    # @param [String] the id of a child GenericFile
    # @return [ActiveFedora::Base] the parent object
    def self.parent_for(id)
      ids = ordered_by_ids(id)
      ActiveFedora::Base.find(ordered_by_ids(id).first) if ids.present?
    end

    def self.ordered_by_ids(id)
      if id.present?
        ActiveFedora::SolrService.query("{!join from=proxy_in_ssi to=id}ordered_targets_ssim:#{id}")
          .map { |x| x["id"] }
      else
        []
      end
    end
  end
end
