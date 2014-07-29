require "sufia/version"
require 'blacklight'
require 'blacklight_advanced_search'
require 'blacklight/gallery'
require 'hydra/head'
require 'hydra-batch-edit'
require 'hydra-editor'
require 'browse-everything'
require 'sufia/models'

require 'rails_autolink'
require 'font-awesome-sass-rails'
require 'tinymce-rails'
require 'tinymce-rails-imageupload'

module Sufia
  extend ActiveSupport::Autoload

  class Engine < ::Rails::Engine
    engine_name 'sufia'

    config.autoload_paths += %W(
      #{config.root}/app/controllers/concerns
      #{config.root}/app/models/concerns
      #{config.root}/app/models/datastreams
      #{Hydra::Engine.root}/app/models/concerns
    )

    config.assets.paths << config.root.join('vendor', 'assets', 'fonts')
    config.assets.precompile << %r(vjs\.(?:eot|ttf|woff)$)
  end
end
