module Hydra
  module Controller
    module DownloadBehavior
      extend ActiveSupport::Concern

      included do
        include Hydra::Controller::ControllerBehavior
        before_filter :authorize_download!
      end

      # Responds to http requests to show the datastream
      def show
        if datastream.new_record?
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
        authorize! :download, datastream
      end

      def asset
        @asset ||= ActiveFedora::Base.find(params[asset_param_key])
      end

      def datastream
        @ds ||= datastream_to_show
      end

      # Override this method to change which datastream is shown.
      # Loads the file specified by the HTTP parameter `:datastream_id`.
      # If this object does not have a datastream by that name, return the default datastream
      # as returned by {#default_content_ds}
      # @return [ActiveFedora::File] the file
      def datastream_to_show
        ds = asset.attached_files[params[:datastream_id]] if params.has_key?(:datastream_id)
        ds ||= default_content_ds
        raise "Unable to find a datastream for #{asset}" if ds.nil?
        ds
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
        {disposition: 'inline', type: datastream.mime_type, filename: datastream_name}
      end

      # Override this if you'd like a different filename
      # @return [String] the filename
      def datastream_name
        params[:filename] || datastream.original_name || (asset.respond_to?(:label) && asset.label) || datastream.id
      end


      # render an HTTP HEAD response
      def content_head
        response.headers['Content-Length'] = datastream.size
        response.headers['Content-Type'] = datastream.mime_type
        head :ok
      end


      # render an HTTP Range response
      def send_range
        _, range = request.headers['HTTP_RANGE'].split('bytes=')
        from, to = range.split('-').map(&:to_i)
        to = datastream.size - 1 unless to
        length = to - from + 1
        response.headers['Content-Range'] = "bytes #{from}-#{to}/#{datastream.size}"
        response.headers['Content-Length'] = "#{length}"
        self.status = 206
        prepare_file_headers
        datastream.stream(request.headers['HTTP_RANGE']) do |block|
          response.stream.write block
        end
      ensure
        response.stream.close
      end

      def send_file_contents
        self.status = 200
        prepare_file_headers
        datastream.stream do |block|
          response.stream.write block
        end
      ensure
        response.stream.close
      end

      def prepare_file_headers
        send_file_headers! content_options
        response.headers['Content-Type'] = datastream.mime_type
        self.content_type = datastream.mime_type
      end

      private

      def default_content_ds
        if asset.class.respond_to?(:default_content_ds)
          asset.attached_files[asset.class.default_content_ds]
        elsif asset.attached_files.key?(DownloadsController.default_content_dsid)
          asset.attached_files[DownloadsController.default_content_dsid]
        end
      end

      module ClassMethods
        def default_content_dsid
          "content"
        end
      end
    end
  end
end

