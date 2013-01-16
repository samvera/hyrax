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

class BatchController < ApplicationController
  include Hydra::Controller::ControllerBehavior
  include Hydra::Controller::UploadBehavior
  include Sufia::Noid # for normalize_identifier method

  before_filter :has_access?
  prepend_before_filter :normalize_identifier, :only=>[:edit, :show, :update, :destroy]

  def edit
    @batch =  Batch.find_or_create(params[:id])
    @generic_file = GenericFile.new
    @generic_file.creator = current_user.name
    @generic_file.title =  @batch.generic_files.map(&:label)
    begin
      @groups = current_user.groups
    rescue
      logger.warn "Can not get to LDAP for user groups"
    end
  end

  def update
    authenticate_user!
    @batch =  Batch.find_or_create(params[:id])
    @batch.status="processing"
    @batch.save
    Sufia.queue.push(BatchUpdateJob.new(current_user.user_key, params))
    flash[:notice] = 'Your files are being processed by ' + t('sufia.product_name') + ' in the background. The metadata and access controls you specified are being applied. Files will be marked <span class="label label-important" title="Private">Private</span> until this process is complete (shouldn\'t take too long, hang in there!). You may need to refresh your dashboard to see these updates.'
    redirect_to sufia.dashboard_index_path
  end
end
