module Hyrax
  class DownloadsController < ApplicationController
    include Hydra::Controller::DownloadBehavior

    def self.default_content_path
      :original_file
    end

    # Render the 404 page if the file doesn't exist.
    # Otherwise renders the file.
    def show
      case file
      when String, File
        # For derivatives stored on the local file system
        response.headers['Accept-Ranges'] = 'bytes'
        response.headers['Content-Length'] = File.size(file).to_s
        send_file file, derivative_download_options
      else
        raise Hyrax::ObjectNotFoundError
      end
    end

    private

      # Override the Hydra::Controller::DownloadBehavior#content_options so that
      # we have an attachement rather than 'inline'
      def content_options
        super.merge(disposition: 'attachment')
      end

      # Override this method if you want to change the options sent when downloading
      # a derivative file
      def derivative_download_options
        { type: mime_type_for(file), disposition: 'inline' }
      end

      # Customize the :read ability in your Ability class, or override this method.
      # Hydra::Ability#download_permissions can't be used in this case because it assumes
      # that files are in a LDP basic container, and thus, included in the asset's uri.
      def authorize_download!
        authorize! :download, params[asset_param_key]
      rescue CanCan::AccessDenied
        redirect_to default_image
      end

      def default_image
        ActionController::Base.helpers.image_path 'default.png'
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

        file_path = Hyrax::DerivativePath.derivative_path_for_reference(params[asset_param_key], file_reference)
        File.exist?(file_path) ? file_path : nil
      end

      def default_file
        default_file_reference = if asset.class.respond_to?(:default_file_path)
                                   asset.class.default_file_path
                                 else
                                   DownloadsController.default_content_path
                                 end
        dereference_file(default_file_reference)
      end

      def mime_type_for(file)
        MIME::Types.type_for(File.extname(file)).first.content_type
      end

      def dereference_file(file_reference)
        return false if file_reference.nil?
        return false unless asset.respond_to?(file_reference)
        file_node = asset.send(file_reference)
        file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers.first)
        file.io
      end

      # Overrides Hydra::Controller::DownloadBehavior#asset
      def asset
        @asset ||= Hyrax::Queries.find_by(id: Valkyrie::ID.new(params[asset_param_key]))
      end
  end
end
