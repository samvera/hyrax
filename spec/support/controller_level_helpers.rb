# frozen_string_literal: true
module ControllerLevelHelpers
  # This provides some common mock methods for view tests.
  # These are normally provided by the controller.
  module ControllerViewHelpers
    def search_state
      @search_state ||= CatalogController.search_state_class.new(params, blacklight_config, controller)
    end

    # This allows you to set the configuration
    # @example: view.blacklight_config = Blacklight::Configuration.new
    attr_writer :blacklight_config

    def blacklight_config
      @blacklight_config ||= CatalogController.blacklight_config
    end

    def blacklight_configuration_context
      @blacklight_configuration_context ||= Blacklight::Configuration::Context.new(controller)
    end
  end

  def initialize_controller_helpers(helper)
    helper.extend ControllerViewHelpers
  end
end
