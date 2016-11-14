# frozen_string_literal: true
module Sufia
  # Returns AdminSets that the current user has permission to use.
  class AdminSetService < CurationConcerns::AdminSetService
    # This performs a two pass query, first getting the AdminSets and then getting the work counts
    # @param [Symbol] access :read or :edit
    # @return [Array<Array>] a list with document, then work count
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
      documents.map do |doc|
        [doc, counts[doc.id]]
      end
    end

    # @param [Symbol] access :read or :edit
    def select_options(access = :read)
      search_results(access).map do |element|
        permission_template = PermissionTemplate.find_by(admin_set_id: element.id)
        visibility = permission_template.visibility if permission_template
        # Add HTML5 'data' attributes corresponding to permission template fields
        # Used to limit visibility options of new works (via JS) when an AdminSet is selected
        [element.to_s, element.id, { 'data-visibility' => visibility }]
      end
    end
  end
end
