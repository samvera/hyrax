# Added to allow for the My controller to show only things I have edit access to
class Sufia::MyWorksSearchBuilder < Sufia::SearchBuilder
  include Sufia::MySearchBuilderBehavior

  self.default_processor_chain = [:add_advanced_search_to_solr] + default_processor_chain
  self.default_processor_chain += [
    :show_only_resources_deposited_by_current_user,
    :show_only_generic_works
  ]
end
