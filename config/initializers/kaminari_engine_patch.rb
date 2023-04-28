# frozen_string_literal: true

# Add support for engine routes to kaminari
Rails.application.config.to_prepare do
  Kaminari::Helpers::Tag.class_eval do
    def page_url_for(page)
      params = params_for(page)
      params[:only_path] = true
      if @options[:route_set]
        @options[:route_set].url_for params
      else
        @template.url_for params
      end
    end
  end
end
