class DirectoryController < ApplicationController
  include Hydra::Controller::ControllerBehavior
  include ScholarSphere::Utils

  # returns true if the user exists and false otherwise
  def user
    render :json => User.directory_attributes(params[:uid])
  end

  def user_attribute
    if params[:attribute] == "groups"
      res = User.groups(params[:uid])
    else
      res = User.directory_attributes(params[:uid], params[:attribute])
    end
    render :json => res
  end

  def user_groups
    render :json => User.groups(params[:uid])
  end

  def group
    puts params[:cn]
    render :json => retry_unless(7.times, lambda { Hydra::LDAP.connection.get_operation_result.code == 53 }) do
      Hydra::LDAP.does_group_exist?(params[:cn]) rescue false
    end
  end
end
