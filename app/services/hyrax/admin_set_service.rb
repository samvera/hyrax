# frozen_string_literal: true
module Hyrax
  # Returns AdminSets that the current user has permission to use.
  class AdminSetService
    attr_reader :context, :search_builder
    class_attribute :default_search_builder
    self.default_search_builder = Hyrax::AdminSetSearchBuilder

    # @param [#repository,#blacklight_config,#current_ability] context
    def initialize(context, search_builder = default_search_builder)
      @context = context
      @search_builder = search_builder
    end

    # @param [Symbol] access :read or :edit
    def search_results(access)
      response = context.repository.search(builder(access))
      response.documents
    end

    # This performs a two pass query, first getting the AdminSets
    # and then getting the work and file counts
    # @param [Symbol] access :read or :edit
    # @return [Array<Array>] a list with document, then work and file count
    def search_results_with_work_count(access)
      documents = search_results(access)
      ids = documents.map(&:id).join(',')
      join_field = "isPartOf_ssim"
      query = "{!terms f=#{join_field}}#{ids}"
      results = ActiveFedora::SolrService.instance.conn.get(
        ActiveFedora::SolrService.select_path,
        params: { fq: query,
                  'facet.field' => join_field }
      )
      counts = results['facet_counts']['facet_fields'][join_field].each_slice(2).to_h
      file_counts = count_files(results)
      documents.map do |doc|
        [doc, counts[doc.id].to_i, file_counts[doc.id]]
      end
    end

    # Return AdminSet selectbox options based on access type
    # @param [Symbol] access :read or :edit
    def select_options(access = :read)
      search_results(access).map do |admin_set|
        [admin_set.to_s, admin_set.id, data_attributes(admin_set)]
      end
    end

    private

      # @param [Symbol] access :read or :edit
      def builder(access)
        search_builder.new(context, access)
      end

      # Create a hash of HTML5 'data' attributes. These attributes are added to select_options and
      # later utilized by Javascript to limit new Work options based on AdminSet selected
      def data_attributes(admin_set)
        attrs = {}

        permission_template = PermissionTemplate.find_by!(admin_set_id: admin_set.id)
        # Leverage all PermissionTemplate release & visibility data attributes (if not blank or false)
        attrs['data-release-date'] = permission_template.release_date unless permission_template.release_date.blank?
        attrs['data-release-before-date'] = true if permission_template.release_before_date?
        attrs['data-visibility'] = permission_template.visibility unless permission_template.visibility.blank?
        attrs
      end

      # Count number of files from admin set works
      # @param [Array] results Solr search result
      # @return [Hash] admin set id keys and file count values
      def count_files(results)
        file_counts = Hash.new(0)
        results['response']['docs'].each do |doc|
          doc['isPartOf_ssim'].each do |id|
            file_counts[id] += doc['file_set_ids_ssim'].length
          end
        end
        file_counts
      end
  end
end
