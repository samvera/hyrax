# frozen_string_literal: true
module Hyrax
  class UserProfilePresenter
    def initialize(user, ability)
      @user = user
      @ability = ability
    end

    attr_reader :user, :ability

    delegate :name, to: :user

    # @return true if the presenter is for the logged in user
    def current_user?
      user == ability.current_user
    end

    def events
      @events ||= if user.respond_to? :profile_events
                    user.profile_events(100)
                  else
                    []
                  end
    end

    # @return [Array<TrophyPresenter>] list of TrophyPresenters for this profile.
    def trophies
      @trophies ||= Hyrax::TrophyPresenter.find_by_user(user)
    end
  end
end
