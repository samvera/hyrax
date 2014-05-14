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
        params[:selected_files].each_pair do |index, file_info| 
          next if file_info.blank? || file_info["url"].blank?
          create_file_from_url(file_info["url"])
        end
        redirect_to self.class.upload_complete_path( params[:batch_id])
      end
      
      # Generic utility for creating GenericFile from a URL
      # Used in to import files using URLs from a file picker like browse_everything 
      def create_file_from_url(url, batch_id=nil)
        @generic_file = ::GenericFile.new(import_url: url, label: File.basename(url)).tap do |gf|
          create_metadata(gf)
          gf.save!
          Sufia.queue.push(ImportUrlJob.new(gf.pid))
        end
      end

  end
end
