module Sufia::FilesController
  module BrowseEverything
    include ActiveSupport::Concern

    def create 
      if params[:selected_files].present?
        create_from_browse_everything(params)
      else
        super
      end
    end

    protected

      def create_from_browse_everything(params)
        Batch.find_or_create(params[:batch_id])        
        params[:selected_files].each_pair do |index, file_info| 
          next if file_info.blank? || file_info["url"].blank?
          create_file_from_url(file_info["url"], file_info["file_name"])
        end
        redirect_to self.class.upload_complete_path( params[:batch_id])
      end
      
      # Generic utility for creating GenericFile from a URL
      # Used in to import files using URLs from a file picker like browse_everything 
      def create_file_from_url(url, file_name)
        generic_file = ::GenericFile.new(import_url: url, label: file_name).tap do |gf|
          actor = Sufia::GenericFile::Actor.new(gf, current_user)
          actor.create_metadata(params[:batch_id])
          gf.save!
          Sufia.queue.push(ImportUrlJob.new(gf.id))
        end
      end

  end
end
