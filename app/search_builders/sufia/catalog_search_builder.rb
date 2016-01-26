class Sufia::CatalogSearchBuilder < Sufia::SearchBuilder
  self.default_processor_chain += [
    :add_access_controls_to_solr_params,
    :add_advanced_parse_q_to_solr,
    :show_works_or_works_that_contain_files
  ]
end
