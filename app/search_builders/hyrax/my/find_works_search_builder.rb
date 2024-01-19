# frozen_string_literal: true
# Search for possible works that user can edit and could be a work's child or parent.
class Hyrax::My::FindWorksSearchBuilder < Hyrax::My::SearchBuilder
  include Hyrax::FilterByType

  self.default_processor_chain += [:filter_on_title, :show_only_other_works, :show_only_works_not_child, :show_only_works_not_parent]

  # Excludes the id that is part of the params
  def initialize(context)
    super(context)
    # Without an id this class will produce an invalid query.
    @id = context.params[:id] || raise("missing required parameter: id")
    @q = context.params[:q]
  end

  def filter_on_title(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [Hyrax::SolrQueryBuilderService.construct_query(title_tesim: @q)]
  end

  def show_only_other_works(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += ["-#{Hyrax::SolrQueryBuilderService.construct_query_for_ids([parsed_id])}"]
  end

  def show_only_works_not_child(solr_parameters)
    ids = Hyrax::SolrService.query("{!field f=id}#{parsed_id}", fl: "member_ids_ssim", rows: 10_000).flat_map { |x| x.fetch("member_ids_ssim", []) }
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += ["-#{Hyrax::SolrQueryBuilderService.construct_query_for_ids([ids])}"]
  end

  def show_only_works_not_parent(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq]  += [
      "-" + Hyrax::SolrQueryBuilderService.construct_query(member_ids_ssim: parsed_id)
    ]
  end

  def only_works?
    true
  end

  # Since Valkyrie objects pass is an Id object, additional parsing is needed.
  def parsed_id
    @id.is_a?(String) ? @id : @id.id
  end
end
