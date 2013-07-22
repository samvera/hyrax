# -*- coding: utf-8 -*-
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

module Sufia
  module FilesController::LocalIngestBehavior
  
    private
    
    def perform_local_ingest
      if ingest_local_file
        redirect_to sufia.batch_edit_path(params[:batch_id])
      else
        flash[:alert] = "Error creating generic file."
        render :new
      end
    end

    def ingest_local_file
      # Ingest files already on disk
      has_directories = false
      files = []
      params[:local_file].each do |filename|
        if File.directory?(File.join(current_user.directory, filename))
          has_directories = true
          Dir[File.join(current_user.directory, filename, '**', '*')].each do |single|
            next if File.directory? single
            logger.info("Ingesting file: #{single}")
            files << single.sub(current_user.directory + '/', '')
            logger.info("after removing the user directory #{current_user.directory} we have: #{files.last}")
          end
        else
          files << filename
        end
      end
      files.each do |filename|
        ingest_one(filename, has_directories)
      end
      true
    end

    def ingest_one(filename, unarranged)
      # do not remove :: 
      @generic_file = ::GenericFile.new
      basename = File.basename(filename)
      @generic_file.label = basename
      @generic_file.relative_path = filename if filename != basename
      Sufia::GenericFile::Actions.create_metadata(@generic_file, current_user, params[:batch_id] )
      Sufia.queue.push(IngestLocalFileJob.new(@generic_file.id, current_user.directory, filename, current_user.user_key))
    end
    
  end # /FilesController::LocalIngestBehavior
end # /Sufia