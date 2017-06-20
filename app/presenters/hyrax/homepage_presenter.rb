module Hyrax
  class HomepagePresenter
    attr_reader :current_ability, :collections

    def initialize(current_ability, collections)
      @current_ability = current_ability
      @collections = collections
    end

    # @return [Boolean] If the current user is a guest and the display_share_button_when_not_logged_in?
    #   is activated, then return true. Otherwise return true if the signed in
    #   user has permission to create at least one kind of work.
    def display_share_button?
      (user_unregistered? && Hyrax.config.display_share_button_when_not_logged_in?) ||
        current_ability.can_create_any_work?
    end

    private

      def user_unregistered?
        current_ability.current_user.new_record? ||
          current_ability.current_user.guest?
      end
  end
end
