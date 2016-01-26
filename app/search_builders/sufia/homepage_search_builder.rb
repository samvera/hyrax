# Added to allow for the My controller to show only things I have edit access to
class Sufia::HomepageSearchBuilder < Sufia::SearchBuilder
  self.default_processor_chain += [:show_only_generic_works, :add_access_controls_to_solr_params]
end
