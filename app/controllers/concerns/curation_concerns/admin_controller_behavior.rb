module CurationConcerns
  module AdminControllerBehavior
    extend ActiveSupport::Concern

    included do
      include AdminPage
      before_action :require_permissions
    end

    def index
      @resource_statistics = @configuration.fetch(:data_sources).fetch(:resource_stats).new
      render 'index'
    end

    def search_builder
      @search_builder ||= ::CatalogController.new.search_builder
    end

    def repository
      @repository ||= ::CatalogController.new.repository
    end

    def workflow
      @status_list = CurationConcerns::Workflow::StatusListService.new(current_user)
    end

    private

      def require_permissions
        authorize! :read, :admin_dashboard
      end

      # Loads the index action if it's only defined in the configuration.
      def action_missing(action)
        index if @configuration[:actions].include?(action)
      end
  end
end
