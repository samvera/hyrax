# Added to allow for the My controller to show only things I have edit access to
class Sufia::MyCollectionsSearchBuilder < Sufia::SearchBuilder
  include Sufia::MySearchBuilderBehavior

  self.default_processor_chain += [
    :show_only_resources_deposited_by_current_user,
    :show_only_collections
  ]
end
