# Added to allow for the My controller to show only things I have edit access to
class Hyrax::HomepageSearchBuilder < Hyrax::SearchBuilder
  include Hyrax::FilterByType
  self.default_processor_chain += [:add_access_controls_to_solr_params]

  def only_works?
    true
  end
end
