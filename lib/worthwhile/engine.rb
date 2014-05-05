#Load blacklight which will give worthwhile views a higher preference than those in blacklight
require 'blacklight'
require 'sufia/models'  

module Worthwhile
  class Engine < ::Rails::Engine
    isolate_namespace Worthwhile
    require 'breadcrumbs_on_rails'

    config.eager_load_paths += %W(
     #{config.root}/app/inputs
    )

    initializer 'worthwhile.initialize' do
    end

    

  end
end
