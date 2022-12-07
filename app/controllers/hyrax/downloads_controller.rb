# frozen_string_literal: true
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
      when String
        # For derivatives stored on the local file system
        send_local_content
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

    def file_set_parent(file_set_id)
      file_set = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: file_set_id, use_valkyrie: Hyrax.config.use_valkyrie?)
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
      association = dereference_file(default_file_reference)
      association&.reader
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
