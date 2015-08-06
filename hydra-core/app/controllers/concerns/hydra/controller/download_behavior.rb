module Hydra
  module Controller
    module DownloadBehavior
      extend ActiveSupport::Concern
      extend Deprecation

      included do
        include Hydra::Controller::ControllerBehavior
        before_filter :authorize_download!
      end

      # Responds to http requests to show the file
      def show
        if file.new_record?
          render_404
        else
          send_content
        end
      end

      protected

      def render_404
        respond_to do |format|
          format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
          format.any  { head :not_found }
        end
      end

      # Override this method if asset PID is not passed in params[:id],
      # for example, in a nested resource.
      def asset_param_key
        :id
      end

      # Customize the :download ability in your Ability class, or override this method
      def authorize_download!
        authorize! :download, file
      end

      def asset
        @asset ||= ActiveFedora::Base.find(params[asset_param_key])
      end

      def datastream
        Deprecation.warn(DownloadBehavior, "datastream is deprecated and will be removed in hydra-head 10.0. Use `file` instead.")
        file
      end

      def file
        @file ||= load_file
      end

      # Override this method to change which file is shown.
      # Loads the file specified by the HTTP parameter `:file_id`.
      # If this object does not have a file by that name, return the default file
      # as returned by {#default_file}
      # @return [ActiveFedora::File] the file
      def load_file
        file_path = params[:file]
        if !file_path && params[:datastream_id]
          Deprecation.warn(DownloadBehavior, "Parameter `datastream_id` is deprecated and will be removed in hydra-head 10.0. Use `file` instead.")
          file_path = params[:datastream_id]
        end
        f = asset.attached_files[file_path] if file_path
        f ||= default_file
        raise "Unable to find a file for #{asset}" if f.nil?
        f
      end

      def datastream_to_show
        Deprecation.warn(DownloadBehavior, "datastream_to_show is deprecated and will be removed in hydra-head 10.0")
        load_file
      end

      # Handle the HTTP show request
      def send_content

        response.headers['Accept-Ranges'] = 'bytes'

        if request.head?
          content_head
        elsif request.headers['HTTP_RANGE']
          send_range
        else
          send_file_contents
        end
      end

      # Create some headers for the datastream
      def content_options
        { disposition: 'inline', type: file.mime_type, filename: file_name }
      end

      # Override this if you'd like a different filename
      # @return [String] the filename
      def datastream_name
        Deprecation.warn(DownloadBehavior, "datastream_name is deprecated and will be removed in hydra-head 10.0, use file_name instead")
        file_name
      end

      # Override this if you'd like a different filename
      # @return [String] the filename
      def file_name
        params[:filename] || file.original_name || (asset.respond_to?(:label) && asset.label) || file.id
      end


      # render an HTTP HEAD response
      def content_head
        response.headers['Content-Length'] = file.size
        response.headers['Content-Type'] = file.mime_type
        head :ok
      end

      # render an HTTP Range response
      def send_range
        _, range = request.headers['HTTP_RANGE'].split('bytes=')
        from, to = range.split('-').map(&:to_i)
        to = file.size - 1 unless to
        length = to - from + 1
        response.headers['Content-Range'] = "bytes #{from}-#{to}/#{file.size}"
        response.headers['Content-Length'] = "#{length}"
        self.status = 206
        prepare_file_headers
        stream_body file.stream(request.headers['HTTP_RANGE'])
      end

      def send_file_contents
        self.status = 200
        prepare_file_headers
        stream_body file.stream
      end

      def prepare_file_headers
        send_file_headers! content_options
        response.headers['Content-Type'] = file.mime_type
        response.headers['Content-Length'] ||= file.size
        # Prevent Rack::ETag from calculating a digest over body
        response.headers['Last-Modified'] = asset.modified_date.utc.strftime("%a, %d %b %Y %T GMT")
        self.content_type = file.mime_type
      end

      private

      def stream_body(iostream)
        iostream.each do |in_buff|
          response.stream.write in_buff
        end
      ensure
        response.stream.close
      end

      def default_content_ds
        Deprecation.warn(DownloadBehavior, "default_content_ds is deprecated and will be removed in hydra-head 10.0, use default_file instead")
        default_file
      end

      def default_file
        if asset.class.respond_to?(:default_file_path)
          asset.attached_files[asset.class.default_file_path]
        elsif asset.class.respond_to?(:default_content_ds)
          Deprecation.warn(DownloadBehavior, "default_content_ds is deprecated and will be removed in hydra-head 10.0, use default_file_path instead")
          asset.attached_files[asset.class.default_content_ds]
        elsif asset.attached_files.key?(DownloadsController.default_file_path)
          asset.attached_files[DownloadsController.default_file_path]
        elsif asset.attached_files.key?(DownloadsController.default_content_dsid)
          Deprecation.warn(DownloadBehavior, "DownloadsController.default_content_dsid is deprecated and will be removed in hydra-head 10.0, use default_file_path instead")
          asset.attached_files[DownloadsController.default_content_dsid]
        end
      end

      module ClassMethods
        def default_content_dsid
          Deprecation.warn(DownloadBehavior, "default_content_dsid is deprecated and will be removed in hydra-head 10.0, use default_file_path instead")
          default_file_path
        end

        def default_file_path
          "content"
        end
      end
    end
  end
end

