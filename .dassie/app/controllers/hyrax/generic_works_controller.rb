# Generated via
#  `rails generate hyrax:work GenericWork`
module Hyrax
  # Generated controller for GenericWork
  class GenericWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    if Hyrax.config.valkyrie_transition?
      self.curation_concern_type = ::GenericWorkResource

      self.work_form_service = Hyrax::FormFactory.new
    else
      self.curation_concern_type = ::GenericWork
    end

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::GenericWorkPresenter
  end
end
