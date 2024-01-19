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
    # Builds and prepopulates a form for the given model.
    #
    # @param model      [Object]
    # @param ability    [Hyrax::Ability]
    # @param controller [ApplicationController]
    #
    # @see https://trailblazer.to/2.0/gems/reform/prepopulator.html
    def build(model, _ability, _controller)
      Hyrax::Forms::ResourceForm.for(resource: model).prepopulate!
    end
  end
end
