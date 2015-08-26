module CurationConcerns
  class ParentService
    # @param [String] the id of a child GenericFile
    # @return [ActiveFedora::Base] the parent object
    def self.parent_for(id)
      ActiveFedora::Aggregation::Proxy.where(proxyFor_ssim: id)
        .map(&:container).first
    end
  end
end
