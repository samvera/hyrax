module Hyrax
  module ManagesEmbargoes
    extend ActiveSupport::Concern

    included do
      attr_accessor :curation_concern
      helper_method :curation_concern
    end

    # This is an override of Hyrax::ApplicationController
    def deny_access(exception)
      redirect_to root_path, alert: exception.message
    end

    def edit
      @curation_concern = find_resource(params[:id])
      authorize! :edit, @curation_concern
    end

    private

      def find_resource(id)
        query_service.find_by(id: Valkyrie::ID.new(id.to_s))
      end

      def query_service
        Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      end
  end
end
