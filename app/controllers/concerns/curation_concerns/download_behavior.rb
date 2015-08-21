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

    # Render the 404 page if the file doesn't exist.
    # Otherwise renders the file.
    def show
      case file
      when ActiveFedora::File
        # For original files that are stored in fedora
        super
      when String
        # For derivatives stored on the local file system
        send_file file, type: mime_type_for(file), disposition: 'inline'
      else
        render_404
      end
    end

    protected

      # Customize the :download ability in your Ability class, or override this method
      def authorize_download!
        # authorize! :download, file # can't use this because Hydra::Ability#download_permissions assumes that files are in Basic Container (and thus include the asset's uri)
        authorize! :read, asset
      end

      # Overrides Hydra::Controller::DownloadBehavior#load_file, which is hard-coded to assume files are in BasicContainer.
      # Override this method to change which file is shown.
      # Loads the file specified by the HTTP parameter `:file`.
      # If this object does not have a file by that name, return the default file
      # as returned by {#default_file}
      # @return [ActiveFedora::File, String, NilClass] Returns the file from the repository or a path to a file on the local file system, if it exists.
      def load_file
        file_reference = params[:file]
        return default_file unless file_reference

        file_path = CurationConcerns::DerivativePath.derivative_path_for_reference(asset, file_reference)
        File.exist?(file_path) ? file_path : nil
      end

      def default_file
        if asset.class.respond_to?(:default_file_path)
          default_file_reference = asset.class.default_file_path
        else
          default_file_reference = DownloadsController.default_content_path
        end
        association = dereference_file(default_file_reference)
        association.reader if association
      end

    private

      def mime_type_for(file)
        MIME::Types.type_for(File.extname(file)).first.content_type
      end

      def dereference_file(file_reference)
        return false if file_reference.nil?
        association = asset.association(file_reference.to_sym)
        association if association && association.is_a?(ActiveFedora::Associations::SingularAssociation)
      end
  end
end
