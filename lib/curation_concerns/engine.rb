#Load blacklight which will give curation_concerns views a higher preference than those in blacklight
require 'blacklight'
require 'curation_concerns/models'
require 'hydra-collections'
require 'hydra-editor'

module CurationConcerns
  class Engine < ::Rails::Engine
    isolate_namespace CurationConcerns
    require 'breadcrumbs_on_rails'

    config.autoload_paths += %W(
     #{config.root}/lib
    )

    initializer 'curation_concerns.initialize' do
      require 'curation_concerns/rails/routes'
    end
  end
end
