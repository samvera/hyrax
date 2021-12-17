# frozen_string_literal: true

module Hyrax
  class SearchService < Blacklight::SearchService
    private

    def scope
      @context[:scope]
    end

    def method_missing(method_name, *arguments, &block)
      if scope&.respond_to?(method_name)
        Deprecation.warn(self.class, "Calling `#{method_name}` on scope " \
          'is deprecated and will be removed in Blacklight 8. Call #to_h first if you ' \
          ' need to use hash methods (or, preferably, use your own SearchState implementation)')
        scope&.public_send(method_name, *arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      scope&.respond_to?(method_name, include_private) || super
    end

    def current_ability
      @current_ability || @context[:current_ability]
    end
  end
end
