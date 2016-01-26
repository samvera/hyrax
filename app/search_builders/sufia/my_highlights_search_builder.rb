# Added to allow for the My controller to show only things I have edit access to
class Sufia::MyHighlightsSearchBuilder < Sufia::SearchBuilder
  include Sufia::MySearchBuilderBehavior

  self.default_processor_chain += [
    :show_only_highlighted_works
  ]
end
