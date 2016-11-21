module Sufia
  # A model name that provides routes that are namespaced to Sufia,
  # without changing the param key.
  #
  # Example:
  #   name = Sufia::Name.new(MyWork)
  #   name.param_key
  #   # => 'my_work'
  #   name.route_key
  #   # => 'sufia_my_works'
  #
  class Name < ActiveModel::Name
    def initialize(klass, namespace = nil, name = nil)
      super
      @route_key          = "sufia_#{ActiveSupport::Inflector.pluralize(@param_key)}"
      @singular_route_key = ActiveSupport::Inflector.singularize(@route_key)
      @route_key << "_index" if @plural == @singular
    end
  end
end
