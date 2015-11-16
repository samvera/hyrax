# Load blacklight which will give curation_concerns views a higher preference than those in blacklight
require 'blacklight'
require 'curation_concerns/models'
require 'hydra-collections'
require 'hydra-editor'
require 'jquery-ui-rails'
require 'qa'

module CurationConcerns
  # Ensures that routes to curation_concerns are prefixed with `curation_concerns_`
  # def self.use_relative_model_naming?
  #   false
  # end

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
