# frozen_string_literal: true
module Hyrax
  module ThemedLayoutController
    extend ActiveSupport::Concern

    included do
      class_attribute :theme
      self.theme = 'hyrax'
      helper_method :theme
      helper_method :show_site_actions?
      helper_method :show_site_search?
    end

    module ClassMethods
      def with_themed_layout(view_name = nil)
        case view_name
        when Symbol
          layout proc { |controller| controller.send(view_name) }
        when String
          layout("#{theme}/#{view_name}")
        else
          layout(theme)
        end
      end
    end

    def show_site_actions?
      true
    end

    def show_site_search?
      true
    end
  end
end
