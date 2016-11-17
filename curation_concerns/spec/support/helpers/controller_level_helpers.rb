module ControllerLevelHelpers
  extend ActiveSupport::Concern
  # def search_state
  #   @search_state ||= Blacklight::SearchState.new(params, blacklight_config)
  # end

  # def blacklight_configuration_context
  #   @blacklight_configuration_context ||= Blacklight::Configuration::Context.new(controller)
  # end
  #
  included do
    # fix for anonymous controllers (https://github.com/rspec/rspec-rails/issues/1321#issuecomment-239157093)
    before { allow(controller).to receive(:_routes).and_return(Rails.application.routes) }
  end

  def initialize_controller_helpers(helper)
    helper.extend ControllerLevelHelpers
    initialize_routing_helpers(helper)
  end

  def initialize_routing_helpers(helper)
    return unless Rails::VERSION::MAJOR >= 5

    helper.class.include ::Rails.application.routes.url_helpers
    helper.class.include ::Rails.application.routes.mounted_helpers if ::Rails.application.routes.respond_to?(:mounted_helpers)
  end
end
