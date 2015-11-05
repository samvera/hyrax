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
        UploadSet.find_or_create(params[:upload_set_id])
        params[:selected_files].each_pair do |_index, file_info|
          next if file_info.blank? || file_info["url"].blank?
          create_file_from_url(file_info["url"], file_info["file_name"])
        end
        redirect_to self.class.upload_complete_path(params[:upload_set_id])
      end

      # Generic utility for creating FileSet from a URL
      # Used in to import files using URLs from a file picker like browse_everything
      def create_file_from_url(url, file_name)
        ::FileSet.new(import_url: url, label: file_name).tap do |fs|
          actor = CurationConcerns::FileSetActor.new(fs, current_user)
          actor.create_metadata(params[:upload_set_id], params[:parent_id])
          fs.save!
          CurationConcerns.queue.push(ImportUrlJob.new(fs.id))
        end
      end
  end
end
