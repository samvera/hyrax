class SingleUseLinksViewerController < ApplicationController
  include Sufia::SingleUseLinksViewerControllerBehavior

  class Ability
    include CanCan::Ability

    attr_reader :single_use_link

    def initialize(user, single_use_link)
      @user = user || User.new

      @single_use_link = single_use_link

      can :read, ActiveFedora::Base do |obj|
        single_use_link.valid? && single_use_link.itemId == obj.id && single_use_link.destroy!
      end if single_use_link
    end
  end

end
