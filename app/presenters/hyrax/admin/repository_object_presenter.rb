module Hyrax
  module Admin
    class RepositoryObjectPresenter
      include Blacklight::SearchHelper

      def initialize(object_type = 'works')
        @object_type = object_type
      end

      def as_json(*)
        counts.map do |k, v|
          [I18n.translate(k, scope: 'hyrax.admin.stats.repository_objects.series'), v]
        end
      end

      private

      delegate :blacklight_config, to: CatalogController

      def counts
        translation = translation_keys
        raw_count = Hash[*results.to_a.flatten]
        @counts ||= raw_count.each_with_object({}) { |(k, v), o| o[translation[k]] = v }
      end

      def search_builder
        if @object_type == 'works'
          Stats::WorkStatusSearchBuilder.new(self)
        else
          Stats::VisibilitySearchBuilder.new(self)
        end
      end

      # results come from Solr in an array where the first item is the status and
      # the second item is the count
      # @example
      #   [ "true", 55, "false", 205, nil, 11 ]
      # @return [#each] an enumerable object of tuples (status and count)
      def results
        facet_results = repository.search(search_builder)
        facet_results.facet_fields[find_object_type].each_slice(2)
      end

      def find_object_type
        if @object_type == 'works'
          IndexesWorkflow.suppressed_field
        elsif @object_type == 'resources'
          'resource_type_tesim'
        else
          'visibility_ssi'
        end
      end

      def translation_keys
        if @object_type == 'works'
          { 'false' => :published, 'true' => :unpublished, nil => :unknown }
        else
          { 'authenticated' => :authenticated, 'open' => :open, 'restricted' => :restricted, nil => :unknown }
        end
      end
    end
  end
end
