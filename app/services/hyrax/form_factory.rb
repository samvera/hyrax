# frozen_string_literal: true

module Hyrax
  ##
  # A factory class for Hyrax forms.
  #
  # @note We use a factory class (rather than a factory method like `.for`) to
  #   provide compatibility with the legacy `Hyrax::WorkFormService`.
  #
  # @example
  #   factory = Hyrax::FormFactory.new
  #
  #   form_change_set = factory.build(work)
  #
  # @since 3.0.0
  class FormFactory
    ##
    # @param model      [Object]
    # @param ability    [Hyrax::Ability]
    # @param controller [ApplicationController]
    def build(model, _ability, _controller)
      Hyrax::Forms::ResourceForm.for(model)
    end
  end
end
