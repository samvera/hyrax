# frozen_string_literal: true
# OVERRIDE hydra-head v12.1.0: update several methods from Hydra::Controller::DownloadBehavior so that we can download files backed by active fedora AND valkyrie

module Hyrax
  class DownloadsController < ApplicationController
    include Hydra::Controller::DownloadBehavior
    include Hyrax::LocalFileDownloadsControllerBehavior
    include Hyrax::WorkflowsHelper # Provides #workflow_restriction?

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
      when Valkyrie::StorageAdapter::File
        # account for valkyrized files
        # new_record? (which is called in "super" above) exists on active fedora files, but not valkyrized files
        if asset.new_record
          render_404
        else
          send_content
        end
      when String
        # For derivatives stored on the local file system
        send_local_content
      else
        raise Hyrax::ObjectNotFoundError
      end
    end

    protected

    def get_mime_type(use_valkyrie:, file:)
      use_valkyrie ? mime_type_for(file.id) : file.mime_type
    end

    # OVERRIDE hydra-head v12.1.0: find valkyrie backed files
    def asset
      @asset ||= if Hyrax.config.use_valkyrie?
                   Hyrax.query_service.find_by(id: Valkyrie::ID.new(params[asset_param_key]))
                 else
                   ActiveFedora::Base.find(params[asset_param_key])
                 end
    end

    def content_head
      response.headers['Content-Length'] = file.size
      # OVERRIDE hydra-head v12.1.0: use #get_mime_type
      head :ok, content_type: get_mime_type(use_valkyrie: Hyrax.config.use_valkyrie?, file: file)
    end

    def prepare_file_headers
      send_file_headers! content_options
      # OVERRIDE hydra-head v12.1.0: use #get_mime_type
      response.headers['Content-Type'] = get_mime_type(use_valkyrie: Hyrax.config.use_valkyrie?, file: file)
      response.headers['Content-Length'] ||= file.size.to_s
      # Prevent Rack::ETag from calculating a digest over body
      # OVERRIDE hydra-head v12.1.0: use "date_modified" which is defined on the asset, instead of "modified_date" which is defined in active-triples by way of active fedora
      response.headers['Last-Modified'] = asset.date_modified.utc.strftime("%a, %d %b %Y %T GMT")
      self.content_type = get_mime_type(use_valkyrie: Hyrax.config.use_valkyrie?, file: file)
    end

    def file_name
      fname = params[:filename] ||
              # OVERRIDE hydra-head v12.1.0: confirm the file responds to "original_name" before calling it
              (file.respond_to?(:original_name) && file.original_name) ||
              (asset.respond_to?(:label) && asset.label) ||
              file.id
      fname = CGI.unescape(fname) if Rails.version >= '6.0'
      fname
    end

    private

    # Override the Hydra::Controller::DownloadBehavior#content_options so that
    # we have an attachment rather than 'inline'
    # OVERRIDE hydra-head v12.1.0: use #get_mime_type
    def content_options
      { disposition: 'attachment', type: get_mime_type(use_valkyrie: Hyrax.config.use_valkyrie?, file: file), filename: file_name }
    end

    # Override this method if you want to change the options sent when downloading
    # a derivative file
    def derivative_download_options
      { type: mime_type_for(file), disposition: 'inline' }
    end

    def file_set_parent(file_set_id)
      file_set = asset
      file_set ||= Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: file_set_id)
      @parent ||=
        case file_set
        when Hyrax::Resource
          Hyrax.query_service.find_parents(resource: file_set).first
        else
          file_set.parent
        end
    end

    # Customize the :read ability in your Ability class, or override this method.
    # Hydra::Ability#download_permissions can't be used in this case because it assumes
    # that files are in a LDP basic container, and thus, included in the asset's uri.
    def authorize_download!
      authorize! :download, params[asset_param_key]
      # Deny access if the work containing this file is restricted by a workflow
      return unless workflow_restriction?(file_set_parent(params[asset_param_key]), ability: current_ability)
      raise Hyrax::WorkflowAuthorizationException
    rescue CanCan::AccessDenied, Hyrax::WorkflowAuthorizationException
      unauthorized_image = Rails.root.join("app", "assets", "images", "unauthorized.png")
      send_file unauthorized_image, status: :unauthorized
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

      if Hyrax.config.use_valkyrie?
        Hyrax.custom_queries.find_file_metadata_by(id: asset.file_ids&.first&.id).file
      else
        association = dereference_file(default_file_reference)
        association&.reader
      end
    end

    def mime_type_for(file)
      MIME::Types.type_for(File.extname(file)).first.content_type
    end

    def dereference_file(file_reference)
      return false if file_reference.nil?
      association = asset.association(file_reference.to_sym)
      association if association&.is_a?(ActiveFedora::Associations::SingularAssociation)
    end
  end
end
