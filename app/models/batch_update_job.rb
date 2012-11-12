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

class BatchUpdateJob
  include Hydra::AccessControlsEnforcement
  include GenericFileHelper
  include Rails.application.routes.url_helpers 

  def self.queue
    :batch_update
  end

  def self.perform(*args)
    new(*args)
  end

  def initialize(login, params, perms)
    params = HashWithIndifferentAccess.new(params)
    perms = HashWithIndifferentAccess.new(perms)
    batch = Batch.find_or_create(params[:id])
    user = User.find_by_login(login)

    saved = []
    denied = []

    batch.generic_files.each do |gf|
      unless user.can? :edit, get_permissions_solr_response_for_doc_id(gf.pid)[1]
        logger.error "User #{user.login} DEEEENIED access to #{gf.pid}!"
        denied << gf
        next
      end
      gf.title = params[:title][gf.pid] if params[:title][gf.pid] rescue gf.label
      gf.update_attributes(params[:generic_file])
      gf.set_visibility(params)

      save_tries = 0
      begin
        gf.save
      rescue RSolr::Error::Http => error
        save_tries += 1
        logger.warn "BatchUpdateJob caught RSOLR error on #{gf.pid}: #{error.inspect}"
        # fail for good if the tries is greater than 3
        rescue_action_without_handler(error) if save_tries >=3
        sleep 0.01
        retry
      end #
      begin
        Resque.enqueue(ContentUpdateEventJob, gf.pid, login)
      rescue Redis::CannotConnectError
        logger.error "Redis is down!"
      end
      
      saved << gf
    end
    batch.update_attributes({status:["Complete"]})
    
    job_user = User.where(login:"batchuser").first
    job_user = User.create(login:"batchuser", email:"batchmail") unless job_user
    
    message = '<a class="batchid ui-helper-hidden">ss-'+batch.noid+'</a>The file(s) '+ file_list(saved)+ " have been saved." unless saved.empty?
    job_user.send_message(user, message, 'Batch upload complete') unless saved.empty?
 
    message = '<a class="batchid ui-helper-hidden">'+batch.noid+'</a>The file(s) '+ file_list(denied)+" could not be updated.  You do not have sufficient privileges to edit it." unless denied.empty?
    job_user.send_message(user, message, 'Batch upload permission denied') unless denied.empty?
     
  end
  
  def file_list ( files)
    return files.map {|gf| '<a href="'+generic_files_path+'/'+gf.noid+'">'+display_title(gf)+'</a>'}.join(', ')
    
  end
  
end
