#Load blacklight which will give worthwhile views a higher preference than those in blacklight
require 'blacklight'

module Spotlight
  class Engine < ::Rails::Engine
    isolate_namespace Worthwhile

  end
end
