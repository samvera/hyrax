module Hyrax
  class HomepagePresenter
    attr_reader :current_ability

    def initialize(current_ability)
      @current_ability = current_ability
    end

    def display_share_button?
      Hyrax.config.always_display_share_button? || current_ability.can_create_any_work?
    end
  end
end
