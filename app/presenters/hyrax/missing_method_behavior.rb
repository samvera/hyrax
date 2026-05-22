# frozen_string_literal: true
module Hyrax
  module MissingMethodBehavior
    private

    def method_missing(method_name, *args, &block)
      return solr_document.public_send(method_name, *args, &block) if solr_document.respond_to?(method_name)
      super
    end

    def respond_to_missing?(method_name, include_private = false)
      solr_document.respond_to?(method_name, include_private) || super
    end
  end
end
