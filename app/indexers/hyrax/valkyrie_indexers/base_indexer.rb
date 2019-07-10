# frozen_string_literal: true
module Hyrax
  module ValkyrieIndexers
    class BaseIndexer
      attr_reader :resource
      def initialize(resource:)
        @resource = resource
      end

      def to_solr
        {
          "id": resource.id.to_s,
          "created_at_dtsi": resource.created_at,
          "updated_at_dtsi": resource.updated_at
        }
      end
    end
  end
end
