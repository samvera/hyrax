# Overrides Hydra::Controller::DownloadBehavior to accommodate the fact that PCDM Objects#files uses direct containment instead of basic containment
module CurationConcerns
  module DownloadBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::DownloadBehavior

    module ClassMethods
      def default_content_path
        :original_file
      end
    end


    # Customize the :download ability in your Ability class, or override this method
    def authorize_download!
      # authorize! :download, file # can't use this because Hydra::Ability#download_permissions assumes that files are in Basic Container (and thus include the asset's uri)
      authorize! :read, asset
    end

    # Overrides Hydra::Controller::DownloadBehavior#load_file, which is hard-coded to assume files are in BasicContainer (PCDM Objects use direct containment)
    # Override this method to change which file is shown.
    # Loads the file specified by the HTTP parameter `:file_id`.
    # If this object does not have a file by that name, return the default file
    # as returned by {#default_file}
    # @return [ActiveFedora::File] the file
    def load_file
      file_reference = params[:file]
      # f = asset.attached_files[file_path] if file_path   # can't use this because attached_files assumes basic containment
      f = asset.send(file_reference) if valid_file_reference?(file_reference)
      f ||= default_file
      raise "Unable to find a file for #{asset}" if f.nil?
      f
    end

    def default_file
      if asset.class.respond_to?(:default_file_path)
        default_file_reference = asset.class.default_file_path
      else
        default_file_reference = DownloadsController.default_content_path
      end
      if valid_file_reference?(default_file_reference)
        return asset.send(default_file_reference)
      else
        return nil
      end
    end

    private

    def valid_file_reference?(file_reference)
      return false if file_reference.nil?
      # the second part of this is covering the fact that directly_contains_one isn't implemented yet, so :original_file, :thumbnail,:extracted_text are not singular associations (yet)
      singular_associations.include?(file_reference.to_sym) || [:original_file, :thumbnail,:extracted_text].include?(file_reference.to_sym)
    end

    def singular_associations
      asset.association_cache.select {|key,assoc| assoc.kind_of?(ActiveFedora::Associations::SingularAssociation)}.keys
    end
  end
end
