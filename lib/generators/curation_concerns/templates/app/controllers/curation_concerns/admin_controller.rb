module CurationConcerns
  # Controller for displaying the Administration console.
  #
  # This controller provides a framework for reading in a configuration
  #  and displaying administrative widgets on an admistrative dashboard.
  #
  # This configuration is included in config/initializers/curation_concerns.rb
  #
  # The administrative dashbord is divided into two columns, a left side menu
  #  and the right action display.
  #
  # The menu is configured by listing actions in display order.
  #
  # The actions are then defined in the configuration and
  # automatically display the partials listed. You can override
  # this default behavior by implementing your action in the controller.
  #
  # The configuration also includes named data sources that can be used in
  #  any view to access system level data.
  #
  # Example Configuration:
  #       @dashboard_configuration ||= {
  #         menu: {
  #             index: {},
  #             other_action: {},
  #             complex_action: {}
  #         },
  #         actions: {
  #           index: {
  #               partials: [
  #                   "total_objects"
  #               ]
  #           },
  #           other_action: {
  #               partials: [
  #                   "other_objects_view"
  #               ]
  #           },
  #           complex_action: {
  #               # rendered in the action
  #           }
  #         },
  #         data_sources: {
  #           resource_stats: CurationConcerns::ResourceStatisticsSource
  #         }
  #      }
  #
  # Example AdminController
  #      class AdminController < ApplicationController
  #         include CurationConcerns::AdminControllerBehavior
  #
  #         def complex_action
  #            # do complex stuff and render how I want
  #            ...
  #         end
  #      end
  #
  class AdminController < ApplicationController
    include CurationConcerns::AdminControllerBehavior
  end
end
