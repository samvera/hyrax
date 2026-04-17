# frozen_string_literal: true
module Qa::Authorities
  class Collections < Qa::Authorities::Base
    class_attribute :search_builder_class
    self.search_builder_class = Hyrax::CollectionSearchBuilder

    def search(_q, controller)
      # The Hyrax::CollectionSearchBuilder expects a current_user
      return [] unless controller.current_user
      search_documents(controller).map do |doc|
        { id: doc.id, label: doc.title, value: doc.id }
      end
    end

    private

    def search_service(controller)
      @search_service ||= Hyrax::SearchService.new(
        config: controller.blacklight_config,
        user_params: controller.params,
        search_builder_class: search_builder_class,
        scope: controller,
        current_ability: controller.current_ability
      )
    end

    def search_documents(controller)
      access = controller.params[:access] || 'read'
      builder = search_service(controller).search_builder
                                          .with(q: controller.params[:q])
                                          .with_access(access)

      Hyrax::SolrService.fetch_all do |rows, start|
        controller.blacklight_config.repository.search(
          builder.query.merge(rows: rows, start: start, fl: 'id,title_tesim,has_model_ssim')
        )
      end
    end
  end
end
