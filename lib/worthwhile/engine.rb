#Load blacklight which will give worthwhile views a higher preference than those in blacklight
require 'blacklight'

module Worthwhile
  class Engine < ::Rails::Engine
    isolate_namespace Worthwhile
    require 'breadcrumbs_on_rails'
    

  end
end
