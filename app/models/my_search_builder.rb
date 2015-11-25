# Added to allow for the My controller to show only things I have edit access to
class MySearchBuilder < Sufia::SearchBuilder
  include Sufia::MySearchBuilderBehavior
end
