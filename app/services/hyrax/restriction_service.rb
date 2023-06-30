# frozen_string_literal: true
module Hyrax
  class RestrictionService
    class << self
      ##
      # @note needed to construct SearchBuilders using self in Blacklight 7+
      delegate :blacklight_config, to: :config

      private

      def presenter_class
        raise "RestrictionService is an Abstract class and should be extended. Implement presenter_class in the subclass"
      end

      def presenters(builder)
        response = repository.search(builder)
        response.documents.map { |d| presenter_class.new(d) }
      end

      def repository
        config.blacklight_config.repository
      end

      def config
        @config ||= ::CatalogController.new
      end
    end
  end
end
