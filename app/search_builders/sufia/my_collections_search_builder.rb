# Added to allow for the My controller to show only things I have edit access to
class Sufia::MyCollectionsSearchBuilder < Sufia::SearchBuilder
  include Sufia::MySearchBuilderBehavior
  include CurationConcerns::FilterByType

  self.default_processor_chain += [:show_only_resources_deposited_by_current_user]

  def only_collections?
    true
  end
end
