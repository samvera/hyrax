# Added to allow for the My controller to show only things I have edit access to
class Hyrax::My::CollectionsSearchBuilder < Hyrax::My::SearchBuilder
  include Hyrax::FilterByType

  def only_collections?
    true
  end
end
