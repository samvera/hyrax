# frozen_string_literal: true
module Hyrax
  class UserProfilePresenter
    ##
    # @param user [::User]
    # @param ability [::Ability]
    def initialize(user, ability)
      @user = user
      @ability = ability
    end

    ##
    # @!attribute [r] ability
    #   @return [::Ability]
    # @!attribute [r] user
    #   @return [::User]
    attr_reader :user, :ability

    delegate :name, to: :user

    ##
    # @return [Boolean] true if the presenter is for the logged in user
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

    ##
    # @return [Array<TrophyPresenter>] list of TrophyPresenters for this profile.
    def trophies
      @trophies ||= Hyrax::TrophyPresenter.find_by_user(user)
    end
  end
end
