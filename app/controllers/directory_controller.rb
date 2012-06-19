class DirectoryController < ApplicationController

  # returns true if the user exists and false otherwise
  def user
    render :json => Hydra::LDAP.does_user_exist?(params[:uid])
  end

  def user_groups
    render :json => Hydra::LDAP.groups_for_user(params[:uid])
  end

  def group
    puts params[:cn]
    render :json => Hydra::LDAP.does_group_exist?(params[:cn])
  end
end
