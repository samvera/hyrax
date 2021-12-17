# frozen_string_literal: true
module Qa::Authorities
  class FindWorks < Qa::Authorities::Base
    class_attribute :search_builder_class
    self.search_builder_class = Hyrax::My::FindWorksSearchBuilder

    def search(_q, controller)
      # The My::FindWorksSearchBuilder expects a current_user
      return [] unless controller.current_user

      response, _docs = search_response(controller)
      docs = response.documents
      docs.map do |doc|
        id = doc.id
        title = doc.title
        { id: id, label: title, value: id }
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

    def search_response(controller)
      access = controller.params[:access] || 'read'

      search_service(controller).search_results do |builder|
        builder.with({ q: controller.params[:q] })
               .with_access(access)
               .rows(100)
      end
    end
  end
end
