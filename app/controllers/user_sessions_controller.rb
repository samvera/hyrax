class UserSessionsController < ApplicationController
  # toggle to set superuser_mode in session
  # Only allows user who can be superusers to set this value in session
  def superuser
    if session[:superuser_mode]
      session[:superuser_mode] = nil
    elsif current_user.can_be_superuser?
      session[:superuser_mode] = true
    end
    redirect_to :back
  end
end