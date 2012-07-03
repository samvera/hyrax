class DirectoryController < ApplicationController

  # returns true if the user exists and false otherwise
  def user
    render :json => ScholarSphere::LDAP.does_user_exist?(params[:uid])
  end

  def user_groups
    render :json => ScholarSphere::LDAP.groups_for_user(params[:uid])
  end

  def group
    puts params[:cn]
    render :json => ScholarSphere::LDAP.does_group_exist?(params[:cn])
  end
end
