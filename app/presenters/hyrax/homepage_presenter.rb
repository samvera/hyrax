module Hyrax
  class HomepagePresenter
    class_attribute :create_work_presenter_class
    self.create_work_presenter_class = Hyrax::SelectTypeListPresenter
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

    # A presenter for selecting a work type to create
    # this is needed here because the selector is in the header on every page
    def create_work_presenter
      @create_work_presenter ||= create_work_presenter_class.new(current_ability.current_user)
    end

    def create_many_work_types?
      create_work_presenter.many?
    end

    def draw_select_work_modal?
      display_share_button? && create_many_work_types?
    end

    def first_work_type
      create_work_presenter.first_model
    end

    private

    def user_unregistered?
      current_ability.current_user.new_record? ||
        current_ability.current_user.guest?
    end
  end
end
