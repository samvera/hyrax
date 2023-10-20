# frozen_string_literal: true
# Added to allow for the My controller to show only things I have edit access to
class Hyrax::My::HighlightsSearchBuilder < Hyrax::SearchBuilder
  include Hyrax::My::SearchBuilderBehavior

  self.default_processor_chain += [:show_only_highlighted_works]

  def show_only_highlighted_works(solr_parameters)
    ids = scope.current_user.trophies.pluck(:work_id)
    solr_parameters[:fq] ||= []
    return solr_parameters[:fq] += ['-id:NEVER_USE_THIS_ID'] if ids.empty?
    solr_parameters[:fq] += [Hyrax::SolrQueryService.new.with_ids(ids: [ids]).build]
  end
end
