module Sufia
  class HomepagePresenter
    attr_reader :current_ability
    include CurationConcerns::AbilityHelper

    def initialize(current_ability)
      @current_ability = current_ability
    end

    delegate :can?, to: :current_ability

    def display_share_button?
      Sufia.config.always_display_share_button || can_ever_create_works?
    end
  end
end
