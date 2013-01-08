# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class DirectoryController < ApplicationController
  #include Hydra::Controller::ControllerBehavior

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
    Group.exists?(params[:cn])
  end
end
