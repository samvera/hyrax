require 'hydra/head'
require 'hydra-editor'
require 'blacklight/gallery'
require 'select2-rails'
require 'hydra-batch-edit'
require 'browse-everything'
require "sufia/version"
require 'blacklight'
require 'blacklight_advanced_search'
require 'sufia/models'

require 'rails_autolink'
require 'font-awesome-rails'
require 'tinymce-rails'
require 'tinymce-rails-imageupload'

module Sufia
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :FormBuilder
  end

  class Engine < ::Rails::Engine
    engine_name 'sufia'

    # Breadcrumbs on rails must be required outside of an initializer or it doesn't get loaded.
    require 'breadcrumbs_on_rails'

    config.autoload_paths += %W(
      #{config.root}/app/controllers/concerns
      #{config.root}/app/models/concerns
      #{Hydra::Engine.root}/app/models/concerns
    )

    config.assets.paths << config.root.join('vendor', 'assets', 'fonts')
    config.assets.precompile << %r(vjs\.(?:eot|ttf|woff)$)
    config.assets.precompile << %r(fontawesome-webfont\.(?:svg|ttf|woff)$)
    config.assets.precompile += %w( ZeroClipboard.swf )
  end
end
