# frozen_string_literal: true
module Hyrax
  # A model name that provides routes that are namespaced to Hyrax,
  # without changing the param key.
  #
  # Example:
  #   name = Hyrax::Name.new(MyWork)
  #   name.param_key
  #   # => 'my_work'
  #   name.route_key
  #   # => 'hyrax_my_works'
  #
  class Name < ActiveModel::Name
    def initialize(klass, namespace = nil, name = nil)
      super
      @route_key          = "hyrax_#{ActiveSupport::Inflector.pluralize(@param_key)}"
      @singular_route_key = ActiveSupport::Inflector.singularize(@route_key)
      @route_key += "_index" if @plural == @singular
    end

    ##
    # Expose the underlying klass which can be helpful when consider that we have the
    # Hyrax::ValkyrieLazyMigration
    attr_reader :klass
  end
end
