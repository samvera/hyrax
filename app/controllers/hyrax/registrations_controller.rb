module Hyrax
  class RegistrationsController < Devise::RegistrationsController
    def new
      return super if Flipflop.account_signup?
      flash[:alert] = t(:'hyrax.account_signup')
      redirect_to root_path
    end

    def create
      return super if Flipflop.account_signup?
      flash[:alert] = t(:'hyrax.account_signup')
      redirect_to root_path
    end
  end
end
