# frozen_string_literal: true
# Added to allow for the My controller to show only things I have edit access to
class Hyrax::My::SharesSearchBuilder < Hyrax::SearchBuilder
  include Hyrax::My::SearchBuilderBehavior

  self.default_processor_chain += [:show_only_shared_files]

  def show_only_shared_files(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      "-" + ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: current_user_key)
    ]
  end
end
