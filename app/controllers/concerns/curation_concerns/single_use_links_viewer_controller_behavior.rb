module CurationConcerns
  module SingleUseLinksViewerControllerBehavior
    extend ActiveSupport::Concern
    include CurationConcerns::DownloadBehavior
    include Blacklight::Base
    include Blacklight::AccessControls::Catalog

    included do
      include ActionDispatch::Routing::PolymorphicRoutes

      skip_before_action :authorize_download!, only: :show
      rescue_from CurationConcerns::SingleUseError, with: :render_single_use_error
      rescue_from CanCan::AccessDenied, with: :render_single_use_error
      rescue_from ActiveRecord::RecordNotFound, with: :render_single_use_error
      class_attribute :presenter_class
      self.presenter_class = CurationConcerns::FileSetPresenter
      copy_blacklight_config_from(::CatalogController)
    end

    def download
      raise not_found_exception unless single_use_link.path == main_app.download_path(id: @asset)
      send_content
    end

    def show
      _, document_list = search_results({ id: single_use_link.itemId }, [:find_one])
      curation_concern = document_list.first

      # Authorize using SingleUseLinksViewerController::Ability
      authorize! :read, curation_concern

      raise not_found_exception unless single_use_link.path == polymorphic_path([main_app, curation_concern])

      # show the file
      @presenter = presenter_class.new(curation_concern, current_ability)

      # create a dowload link that is single use for the user since we do not just want to show metadata we want to access it too
      @su = single_use_link.create_for_path main_app.download_path(curation_concern.id)
      @download_link = curation_concerns.download_single_use_link_path(@su.downloadKey)
    end

    protected

      def content_options
        super.tap do |options|
          options[:disposition] = 'attachment' if action_name == 'download'
        end
      end

      # This is called in a before filter. It causes @asset to be set.
      def authorize_download!
        authorize! :read, asset
      end

      def single_use_link
        @single_use_link ||= SingleUseLink.find_by_downloadKey!(params[:id])
      end

      def not_found_exception
        CurationConcerns::SingleUseError.new('Single-Use Link Not Found')
      end

      def asset
        @asset ||= ActiveFedora::Base.find(single_use_link.itemId)
      end

      def current_ability
        @current_ability ||= SingleUseLinksViewerController::Ability.new current_user, single_use_link
      end

      def render_single_use_error(exception)
        logger.error("Rendering PAGE due to exception: #{exception.inspect} - #{exception.backtrace if exception.respond_to? :backtrace}")
        render template: '/error/single_use_error', layout: "error", formats: [:html], status: 404
      end

      def _prefixes
        # This allows us to use the attributes templates in curation_concerns/base
        @_prefixes ||= super + ['curation_concerns/base']
      end
  end
end
