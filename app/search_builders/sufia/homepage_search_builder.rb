# Added to allow for the My controller to show only things I have edit access to
class Sufia::HomepageSearchBuilder < Sufia::SearchBuilder
  include CurationConcerns::FilterByType
  self.default_processor_chain += [:add_access_controls_to_solr_params]

  def only_works?
    true
  end
end
