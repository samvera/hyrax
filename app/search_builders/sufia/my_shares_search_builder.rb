# Added to allow for the My controller to show only things I have edit access to
class Sufia::MySharesSearchBuilder < Sufia::SearchBuilder
  include Sufia::MySearchBuilderBehavior

  self.default_processor_chain += [:show_only_shared_files]

  def show_only_shared_files(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      "-" + ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: scope.current_user.user_key)
    ]

    solr_parameters[:fq] += ['-suppressed_bsi:true']
  end
end
