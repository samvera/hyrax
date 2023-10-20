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
    solr_parameters[:fq] += [Hyrax::SolrQueryService.new.with_field_pairs(field_pairs: { title_tesim: @q }).build]
  end

  def show_only_other_works(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += ["-#{Hyrax::SolrQueryService.new.with_ids(ids: [@id]).build}"]
  end

  def show_only_works_not_child(solr_parameters)
    ids = Hyrax::SolrService.query("{!field f=id}#{@id}", fl: "member_ids_ssim", rows: 10_000).flat_map { |x| x.fetch("member_ids_ssim", []) }
    solr_parameters[:fq] ||= []
    return solr_parameters[:fq] += ['-id:NEVER_USE_THIS_ID'] if ids.empty?
    solr_parameters[:fq] += ["-#{Hyrax::SolrQueryService.new.with_ids(ids: [ids]).build}"]
  end

  def show_only_works_not_parent(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq]  += [
      "-" + Hyrax::SolrQueryService.new.with_field_pairs(field_pairs: { member_ids_ssim: @id }).build
    ]
  end

  def only_works?
    true
  end
end
