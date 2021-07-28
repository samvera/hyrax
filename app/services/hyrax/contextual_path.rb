# frozen_string_literal: true
module Hyrax
  ##
  # @api public
  #
  # Provides a polymorphic path for a target object (presenter) nested under the
  # path of the parent, if given.
  #
  # @see WorkShowPresenter#contextual_path
  #
  # @example
  #   Hyrax::ContextualPath.new(my_file_set, parent_object).show
  #   # => "/concerns/parent/id4parent/file_sets/id4file_set"
  #
  # @example with a nil parent
  #   Hyrax::ContextualPath.new(my_file_set, nil).show
  #   # => "/concerns/file_sets/id4file_set"
  #
  class ContextualPath
    include Rails.application.routes.url_helpers
    include ActionDispatch::Routing::PolymorphicRoutes
    attr_reader :presenter, :parent_presenter

    ##
    # @param presenter [#model_name] an ActiveModel-like target object
    # @param parent_presenter [#id, nil] an ActiveModel-like presenter for the
    #   target's parent
    def initialize(presenter, parent_presenter)
      @presenter = presenter
      @parent_presenter = parent_presenter
    end

    ##
    # @return [String]
    def show
      if parent_presenter
        polymorphic_path([:hyrax, :parent, presenter.model_name.singular.to_sym],
                         parent_id: parent_presenter.id,
                         id: presenter.id)
      else
        polymorphic_path([presenter])
      end
    end
  end
end
