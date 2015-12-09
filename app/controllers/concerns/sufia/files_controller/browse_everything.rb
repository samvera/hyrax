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
        upload_set_id = params.fetch(:upload_set_id)
        parent = ActiveFedora::Base.find(params.fetch(:parent_id))
        UploadSet.find_or_create(upload_set_id)
        params[:selected_files].each_pair do |_index, file_info|
          next if file_info.blank? || file_info["url"].blank?
          create_file_from_url(file_info["url"], file_info["file_name"], parent)
        end
        redirect_to self.class.upload_complete_path(upload_set_id)
      end

      # Generic utility for creating FileSet from a URL
      # Used in to import files using URLs from a file picker like browse_everything
      def create_file_from_url(url, file_name, parent)
        ::FileSet.new(import_url: url, label: file_name) do |fs|
          actor = CurationConcerns::FileSetActor.new(fs, current_user)
          actor.create_metadata(parent)
          fs.save!
          ImportUrlJob.perform_later(fs.id)
        end
      end
  end
end
