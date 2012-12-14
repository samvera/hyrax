# Monkey patch so that it uses the engine routes. See https://github.com/amatsuda/kaminari/issues/323
module Kaminari
  module Helpers
    class Tag
      def page_url_for(page)
        #@template.url_for @params.merge(@param_name => (page <= 1 ? nil : page)).symbolize_keys
        Sufia::Engine.routes.url_helpers.url_for @params.merge(@param_name => (page <= 1 ? nil : page), :only_path=>true).symbolize_keys
      end
    end
  end
end
