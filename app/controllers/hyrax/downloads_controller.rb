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
      when ActiveFedora::File
        # For original files that are stored in fedora
        super
      when String
        # For derivatives stored on the local file system
        send_content
      else
        raise ActiveFedora::ObjectNotFoundError
      end
    end

    protected

      # Override
      # render an HTTP Range response
      # rubocop:disable  Metrics/AbcSize
      def send_range
        _, range = request.headers['Range'].split('bytes=')
        from, to = range.split('-').map(&:to_i)
        to = file_size - 1 unless to
        length = to - from + 1
        response.headers['Content-Range'] = "bytes #{from}-#{to}/#{file_size}"
        response.headers['Content-Length'] = length.to_s
        self.status = 206
        prepare_file_headers
        if file.is_a? String
          # For derivatives stored on the local file system
          send_data IO.binread(file, length, from), derivative_download_options.merge(status: status)
        else
          stream_body file.stream(request.headers['Range'])
        end
      end
      # rubocop:enable  Metrics/AbcSize

      # Override
      def send_file_contents
        self.status = 200
        prepare_file_headers
        if file.is_a? String
          # For derivatives stored on the local file system
          send_file file, derivative_download_options
        else
          stream_body file.stream
        end
      end

      def file_size
        @file_size ||= File.size(file) if file.is_a? String
        @file_size ||= file.size
      end

      def file_mime_type
        @file_mime_type ||= mime_type_for(file) if file.is_a? String
        @file_mime_type ||= file.mime_type
      end

      # Override
      # @return [String] the filename
      def file_name
        @file_name ||= params[:filename] || File.basename(file) || (asset.respond_to?(:label) && asset.label) if file.is_a? String
        @file_name ||= super
      end

      def file_last_modified
        @file_last_modified ||= File.mtime(file) if file.is_a? String
        @file_last_modified ||= asset.modified_date
      end

      # Override
      # render an HTTP HEAD response
      def content_head
        response.headers['Content-Length'] = file_size.to_s
        head :ok, content_type: file_mime_type
      end

      # Override
      def prepare_file_headers
        send_file_headers! content_options
        response.headers['Content-Type'] = file_mime_type
        response.headers['Content-Length'] ||= file_size.to_s
        # Prevent Rack::ETag from calculating a digest over body
        response.headers['Last-Modified'] = file_last_modified.utc.strftime("%a, %d %b %Y %T GMT")
        self.content_type = file_mime_type
      end

    private

      # Override the Hydra::Controller::DownloadBehavior#content_options so that
      # we have an attachement rather than 'inline'
      def content_options
        { type: file_mime_type, filename: file_name, disposition: 'attachment' }
      end

      # Override this method if you want to change the options sent when downloading
      # a derivative file
      def derivative_download_options
        { type: file_mime_type, filename: file_name, disposition: 'inline' }
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
      # @return [ActiveFedora::File, File, NilClass] Returns the file from the repository or a path to a file on the local file system, if it exists.
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
        association = dereference_file(default_file_reference)
        association.reader if association
      end

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
