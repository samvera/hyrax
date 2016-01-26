require 'legato' # TODO: we shouldn't need to require this
module Sufia
  class Download
    extend ::Legato::Model

    metrics :totalEvents
    dimensions :eventCategory, :eventAction, :eventLabel, :date
    filter :for_file, &->(id) { matches(:eventLabel, id) }
  end
end
