module Hyrax
  class ValkyrieLocator
    delegate :query_service, to: :metadata_adapter

    def locate(gid)
      if gid.model_class < Valkyrie::Resource
        query_service.find_by(id: Valkyrie::ID.new(gid.model_id))
      else
        GlobalID::Locator::DEFAULT_LOCATOR.locate(gid)
      end
    end

    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end
  end
end
