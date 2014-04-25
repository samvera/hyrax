module Sufia
  class Download
    extend Legato::Model

    metrics :totalEvents
    dimensions :eventCategory, :eventAction, :eventLabel, :date
    filter :for_file, &lambda {|id| matches(:eventLabel, id)}
  end 
end
