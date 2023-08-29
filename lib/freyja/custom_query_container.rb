# frozen_string_literal: true
module Freyja
  class CustomQueryContainer < Valkyrie::Persistence::CustomQueryContainer
    def method_missing(method_name, *args, **opts)
      query_service.services.each do |service|
        return service.custom_queries.send(method_name, *args, **opts) if service.custom_queries.respond_to?(method_name)
      end
      super
    end
  end
end
